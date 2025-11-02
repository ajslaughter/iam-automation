<#
.SYNOPSIS
    Builds departmental organizational units, security groups, and users in Active Directory.

.DESCRIPTION
    Creates a top-level Departments OU (or uses an existing one) and then creates three child
    OUs for IT, Marketing, and Finance. Within each departmental OU the script ensures a set
    of security groups and users exist, adding users to the appropriate groups. The script
    is written to be modular and idempotent so that rerunning it will not create duplicate
    objects.

.PARAMETER DomainDN
    The distinguished name of the Active Directory domain (e.g. "DC=contoso,DC=com").

.PARAMETER BaseOUName
    The name of the parent organizational unit under which departmental OUs should be
    created. Defaults to "Departments".

.PARAMETER Credential
    Optional credentials to use when connecting to Active Directory. If not supplied the
    current user context is used.

.PARAMETER DepartmentDefinitions
    Optional array of hashtables describing departments, groups, and users to provision.
    When omitted the script provisions default IT, Marketing, and Finance structures.

.EXAMPLE
    PS> $password = ConvertTo-SecureString 'Pass@word1' -AsPlainText -Force
    PS> $userTemplate = @{ DefaultPassword = $password; ChangePasswordAtLogon = $true }
    PS> .\New-DeptStructure.ps1 -DomainDN 'DC=contoso,DC=com' -UserTemplate $userTemplate -Verbose

    Creates or updates the departmental structure in the contoso.com domain using the
    provided default password for any new user accounts.

.EXAMPLE
    PS> $departments = @(
    >>     @{ Name = 'HR'; Groups = @(@{ Name = 'HR-Staff' }) ; Users = @(@{ SamAccountName = 'hr.jlee'; GivenName = 'Jordan'; Surname = 'Lee'; Groups = @('HR-Staff') }) }
    >> )
    PS> .\New-DeptStructure.ps1 -DomainDN 'DC=contoso,DC=com' -DepartmentDefinitions $departments -Credential (Get-Credential)

    Provisions a custom Human Resources departmental structure using alternate credentials.

.NOTES
    Author: IAM Automation Assistant
    The ActiveDirectory module must be available on the machine running this script.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DomainDN,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BaseOUName = 'Departments',

[Parameter()]
[System.Management.Automation.PSCredential]$Credential,

[Parameter()]
[hashtable]$UserTemplate = @{}

[Parameter()]
[hashtable[]]$DepartmentDefinitions
)

# Initialize a script-scoped hashtable used for credential splatting.
$script:credentialArgs = @{}

if (-not $UserTemplate) {
    $UserTemplate = @{}
}

if ($UserTemplate.ContainsKey('DefaultPassword') -and -not ($UserTemplate.DefaultPassword -is [System.Security.SecureString])) {
    throw 'UserTemplate.DefaultPassword must be provided as a SecureString.'
}

# region Helper Functions

function Import-ActiveDirectoryModule {
    <#
        .SYNOPSIS
            Ensures the ActiveDirectory module is imported.
    #>
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        throw "Failed to import the ActiveDirectory module. Ensure RSAT tools are installed. Error: $_"
    }
}

function Get-FullOuPath {
    <#
        .SYNOPSIS
            Builds a distinguished name for a child OU given the parent DN and OU name.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ParentDN
    )

    return "OU=$Name,$ParentDN"
}

function New-OrganizationalUnitIfMissing {
    <#
        .SYNOPSIS
            Creates an organizational unit when it does not already exist.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ParentDN
    )

    $ouPath = Get-FullOuPath -Name $Name -ParentDN $ParentDN

    if (-not (Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction SilentlyContinue @credentialArgs)) {
        if ($PSCmdlet.ShouldProcess("OU=$Name", "Create organizational unit under $ParentDN")) {
            New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ProtectedFromAccidentalDeletion $true @credentialArgs | Out-Null
            Write-Verbose "Created OU '$Name' in '$ParentDN'."
        }
    }
    else {
        Write-Verbose "OU '$Name' already exists under '$ParentDN'."
    }

    return $ouPath
}

function Ensure-ADGroup {
    <#
        .SYNOPSIS
            Ensures a security group exists with the desired attributes.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$OuPath,

        [string]$Description,

        [ValidateSet('DomainLocal', 'Global', 'Universal')]
        [string]$Scope = 'Global'
    )

    $group = Get-ADGroup -LDAPFilter "(samAccountName=$Name)" -SearchBase $OuPath -ErrorAction SilentlyContinue @credentialArgs

    if (-not $group) {
        if ($PSCmdlet.ShouldProcess($Name, "Create security group")) {
            New-ADGroup -Name $Name -SamAccountName $Name -GroupCategory Security -GroupScope $Scope -Path $OuPath -Description $Description @credentialArgs | Out-Null
            Write-Verbose "Created group '$Name' in '$OuPath'."
        }
    }
    elseif ($Description -and $group.Description -ne $Description) {
        if ($PSCmdlet.ShouldProcess($Name, "Update group description")) {
            Set-ADGroup -Identity $group -Description $Description @credentialArgs
            Write-Verbose "Updated description for group '$Name'."
        }
    }

    return $Name
}

function Ensure-ADUser {
    <#
        .SYNOPSIS
            Ensures a user account exists and has the requested group memberships.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$UserDefinition,

        [Parameter(Mandatory = $true)]
        [string]$OuPath
    )

    $sam = $UserDefinition.SamAccountName
    if (-not $sam) {
        throw 'User definition must include a SamAccountName.'
    }

    $user = Get-ADUser -LDAPFilter "(samAccountName=$sam)" -SearchBase $OuPath -ErrorAction SilentlyContinue @credentialArgs

    if (-not $user) {
        if (-not $UserDefinition.Password -and -not $UserTemplate.DefaultPassword) {
            throw "No password provided for new user '$sam'. Specify Password in the user definition or provide DefaultPassword in -UserTemplate."
        }

        $password = if ($UserDefinition.Password) { $UserDefinition.Password } else { $UserTemplate.DefaultPassword }
        if (-not ($password -is [System.Security.SecureString])) {
            throw "Password for user '$sam' must be a SecureString."
        }

        $displayName = if ($UserDefinition.DisplayName) {
            $UserDefinition.DisplayName
        }
        elseif ($UserDefinition.GivenName -and $UserDefinition.Surname) {
            "{0} {1}" -f $UserDefinition.GivenName, $UserDefinition.Surname
        }
        else {
            $sam
        }

        $userParams = @{
            Name            = $displayName
            SamAccountName  = $sam
            AccountPassword = $password
            Enabled         = $true
            Path            = $OuPath
        }

        if ($UserDefinition.GivenName) { $userParams['GivenName'] = $UserDefinition.GivenName }
        if ($UserDefinition.Surname) { $userParams['Surname'] = $UserDefinition.Surname }
        if ($UserDefinition.UserPrincipalName) { $userParams['UserPrincipalName'] = $UserDefinition.UserPrincipalName }
        if ($Credential) { $userParams['Credential'] = $Credential }

        if ($UserTemplate.ChangePasswordAtLogon) {
            $userParams["ChangePasswordAtLogon"] = $true
        }

        if ($PSCmdlet.ShouldProcess($sam, "Create user")) {
            New-ADUser @userParams
            Write-Verbose "Created user '$sam' in '$OuPath'."
        }
    }
    else {
        Write-Verbose "User '$sam' already exists in '$OuPath'."
    }

    if ($UserDefinition.Groups) {
        foreach ($groupName in $UserDefinition.Groups) {
            $group = Get-ADGroup -Identity $groupName -ErrorAction SilentlyContinue @credentialArgs
            if ($null -eq $group) {
                Write-Warning "Group '$groupName' was not found when adding user '$sam'."
                continue
            }

            $alreadyMember = Get-ADGroupMember -Identity $group @credentialArgs -ErrorAction SilentlyContinue | Where-Object { $_.SamAccountName -eq $sam }

            if ($alreadyMember) {
                Write-Verbose "User '$sam' is already a member of '$groupName'."
                continue
            }

            if ($PSCmdlet.ShouldProcess($sam, "Add to group $groupName")) {
                Add-ADGroupMember -Identity $group -Members $sam @credentialArgs -ErrorAction Stop
                Write-Verbose "Added user '$sam' to group '$groupName'."
            }
        }
    }
}

# endregion Helper Functions

Import-ActiveDirectoryModule

$script:credentialArgs = if ($Credential) { @{ Credential = $Credential } } else { @{} }

$baseOuPath = Get-FullOuPath -Name $BaseOUName -ParentDN $DomainDN
$null = New-OrganizationalUnitIfMissing -Name $BaseOUName -ParentDN $DomainDN

# Default department definitions. Update the UPN suffixes to match your environment.
$defaultDepartments = @(
    @{
        Name   = 'IT'
        Groups = @(
            @{ Name = 'IT-Admins'; Description = 'IT department administrators with elevated privileges.' },
            @{ Name = 'IT-ServiceDesk'; Description = 'IT service desk analysts and technicians.' },
            @{ Name = 'IT-Staff'; Description = 'General IT department staff.' }
        )
        Users  = @(
            @{ SamAccountName = 'it.jdoe'; GivenName = 'John';  Surname = 'Doe'; DisplayName = 'John Doe';  UserPrincipalName = 'it.jdoe@contoso.com'; Groups = @('IT-Admins', 'IT-Staff') },
            @{ SamAccountName = 'it.asmith'; GivenName = 'Alice'; Surname = 'Smith'; DisplayName = 'Alice Smith'; UserPrincipalName = 'it.asmith@contoso.com'; Groups = @('IT-ServiceDesk', 'IT-Staff') }
        )
    }
    @{
        Name   = 'Marketing'
        Groups = @(
            @{ Name = 'Marketing-Managers'; Description = 'Marketing leadership team.' },
            @{ Name = 'Marketing-Creatives'; Description = 'Creative and design staff.' },
            @{ Name = 'Marketing-Staff'; Description = 'All marketing department staff.' }
        )
        Users  = @(
            @{ SamAccountName = 'm.nguyen'; GivenName = 'Minh'; Surname = 'Nguyen'; DisplayName = 'Minh Nguyen'; UserPrincipalName = 'm.nguyen@contoso.com'; Groups = @('Marketing-Managers', 'Marketing-Staff') },
            @{ SamAccountName = 'm.patel'; GivenName = 'Priya'; Surname = 'Patel'; DisplayName = 'Priya Patel'; UserPrincipalName = 'm.patel@contoso.com'; Groups = @('Marketing-Creatives', 'Marketing-Staff') }
        )
    }
    @{
        Name   = 'Finance'
        Groups = @(
            @{ Name = 'Finance-Managers'; Description = 'Finance leadership and controllers.' },
            @{ Name = 'Finance-Analysts'; Description = 'Financial analysts and accountants.' },
            @{ Name = 'Finance-Staff'; Description = 'All finance department staff.' }
        )
        Users  = @(
            @{ SamAccountName = 'f.garcia'; GivenName = 'Fernanda'; Surname = 'Garcia'; DisplayName = 'Fernanda Garcia'; UserPrincipalName = 'f.garcia@contoso.com'; Groups = @('Finance-Managers', 'Finance-Staff') },
            @{ SamAccountName = 'f.johnson'; GivenName = 'Frank'; Surname = 'Johnson'; DisplayName = 'Frank Johnson'; UserPrincipalName = 'f.johnson@contoso.com'; Groups = @('Finance-Analysts', 'Finance-Staff') }
        )
    }
)

$departments = if ($DepartmentDefinitions) { $DepartmentDefinitions } else { $defaultDepartments }

foreach ($department in $departments) {
    if (-not $department.Name) {
        throw 'Each department definition must include a Name property.'
    }

    $departmentOuPath = New-OrganizationalUnitIfMissing -Name $department.Name -ParentDN $baseOuPath

    foreach ($groupDef in $department.Groups) {
        $groupParams = @{
            Name        = $groupDef.Name
            OuPath      = $departmentOuPath
            Description = $groupDef.Description
        }

        if ($groupDef.Scope) { $groupParams['Scope'] = $groupDef.Scope }

        Ensure-ADGroup @groupParams | Out-Null
    }

    foreach ($userDef in $department.Users) {
        if ($UserTemplate.ContainsKey('DefaultPassword') -and -not $userDef.ContainsKey('Password')) {
            $userDef.Password = $UserTemplate.DefaultPassword
        }

        Ensure-ADUser -UserDefinition $userDef -OuPath $departmentOuPath
    }
}

Write-Verbose 'Departmental structure provisioning completed.'
