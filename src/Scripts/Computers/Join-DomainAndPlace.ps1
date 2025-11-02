[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter()]
    [string]$TargetOUDN,

    [Parameter()]
    [string]$RenameTo,

    [Parameter()]
    [switch]$Reboot,

    [Parameter()]
    [string]$TargetComputer,

    [Parameter()]
    [string]$DomainName,

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential
)

#requires -Modules Microsoft.PowerShell.Management, ActiveDirectory

function Invoke-LocalJoin {
    param(
        [System.Management.Automation.PSCmdlet]$Cmdlet,
        [string]$DomainName,
        [string]$TargetOUDN,
        [string]$RenameTo,
        [switch]$Reboot,
        [System.Management.Automation.PSCredential]$Credential
    )

    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $currentName = $cs.Name
    $finalName = if ($RenameTo) { $RenameTo } else { $currentName }

    if (-not $cs.PartOfDomain -or ($DomainName -and $cs.Domain -ne $DomainName)) {
        if (-not $DomainName) {
            throw 'DomainName must be specified when joining a computer to the domain.'
        }

        if ($Cmdlet.ShouldProcess($currentName, "Join domain '$DomainName'")) {
            Write-Verbose "Joining computer '$currentName' to domain '$DomainName'."
            $params = @{ DomainName = $DomainName; ErrorAction = 'Stop' }
            if ($Credential) { $params.Credential = $Credential }
            Add-Computer @params
        }
    } else {
        Write-Verbose "Computer '$currentName' already a member of domain '$($cs.Domain)'."
    }

    if ($RenameTo -and $currentName -ne $RenameTo) {
        if ($Cmdlet.ShouldProcess($currentName, "Rename computer to '$RenameTo'")) {
            Write-Verbose "Renaming computer from '$currentName' to '$RenameTo'."
            Rename-Computer -NewName $RenameTo -Force -ErrorAction Stop
            $finalName = $RenameTo
        }
    } else {
        Write-Verbose 'Rename not required.'
    }

    if ($Reboot) {
        if ($Cmdlet.ShouldProcess($finalName, 'Restart computer to complete domain join')) {
            Write-Verbose "Restarting computer '$finalName' to finalize domain join."
            Restart-Computer -Force -ErrorAction Stop
        }
    }

    return $finalName
}

$executionTarget = if ($TargetComputer) { $TargetComputer } else { $ComputerName }
$finalName = $null

if ($TargetComputer -and $TargetComputer -ne $env:COMPUTERNAME) {
    Write-Verbose "Executing join workflow remotely on '$TargetComputer'."
    if ($PSCmdlet.ShouldProcess($TargetComputer, 'Remote domain join and placement')) {
        $invokeParams = @{ ComputerName = $TargetComputer }
        if ($Credential) { $invokeParams.Credential = $Credential }
        $scriptBlock = {
            param($DomainName,$TargetOUDN,$RenameTo,$Reboot,$Credential)
            Import-Module Microsoft.PowerShell.Management | Out-Null
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem
            $currentName = $cs.Name
            $finalName = if ($RenameTo) { $RenameTo } else { $currentName }

            if (-not $cs.PartOfDomain -or ($DomainName -and $cs.Domain -ne $DomainName)) {
                if (-not $DomainName) {
                    throw 'DomainName must be provided for remote joins.'
                }
                $params = @{ DomainName = $DomainName; ErrorAction = 'Stop' }
                if ($Credential) { $params.Credential = $Credential }
                Add-Computer @params
            }

            if ($RenameTo -and $currentName -ne $RenameTo) {
                Rename-Computer -NewName $RenameTo -Force -ErrorAction Stop
                $finalName = $RenameTo
            }

            if ($Reboot) {
                Restart-Computer -Force -ErrorAction Stop
            }

            return $finalName
        }

        $finalName = Invoke-Command @invokeParams -ScriptBlock $scriptBlock -ArgumentList $DomainName,$TargetOUDN,$RenameTo,$Reboot,$Credential
    }
} else {
    $finalName = Invoke-LocalJoin -Cmdlet $PSCmdlet -DomainName $DomainName -TargetOUDN $TargetOUDN -RenameTo $RenameTo -Reboot:$Reboot.IsPresent -Credential $Credential
}

if (-not $finalName) {
    $finalName = if ($RenameTo) { $RenameTo } else { $ComputerName }
}

if ($TargetOUDN) {
    try {
        $computer = Get-ADComputer -Identity $finalName -ErrorAction Stop -Properties DistinguishedName
    } catch {
        Write-Warning "Unable to locate computer '$finalName' in Active Directory. Ensure the join completed. $_"
        return
    }

    if ($computer.DistinguishedName -notlike "*,${TargetOUDN}") {
        if ($PSCmdlet.ShouldProcess($computer.Name, "Move computer to '$TargetOUDN'")) {
            Write-Verbose "Moving computer '$($computer.Name)' to '$TargetOUDN'."
            Move-ADObject -Identity $computer.DistinguishedName -TargetPath $TargetOUDN -ErrorAction Stop
        }
    } else {
        Write-Verbose "Computer '$($computer.Name)' already resides under '$TargetOUDN'."
    }
}
