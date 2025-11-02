Import-Module (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'src/Modules/IamLab/IamLab.psd1') -Force

Describe 'New-LabOU' {
    BeforeEach {
        Mock Ensure-Module {}
        Mock Write-LabLog {}
        Mock Get-ADOrganizationalUnit -MockWith { [pscustomobject]@{ DistinguishedName='OU=IT,OU=Company,DC=corp,DC=local'; ProtectedFromAccidentalDeletion = $true } }
        Mock Set-ADOrganizationalUnit {}
        Mock New-ADOrganizationalUnit {}
    }

    It 'does not create when OU already exists' {
        New-LabOU -Name 'IT' -Path 'OU=Company,DC=corp,DC=local' | Out-Null
        Assert-MockCalled -CommandName New-ADOrganizationalUnit -Times 0
    }

    It 'creates when OU is missing' {
        $script:ouCall = 0
        Mock Get-ADOrganizationalUnit -MockWith {
            $script:ouCall++
            if ($script:ouCall -eq 1) { return $null }
            return [pscustomobject]@{ DistinguishedName='OU=IT,OU=Company,DC=corp,DC=local'; ProtectedFromAccidentalDeletion = $true }
        }

        New-LabOU -Name 'IT' -Path 'OU=Company,DC=corp,DC=local' | Out-Null
        Assert-MockCalled -CommandName New-ADOrganizationalUnit -Times 1
    }
}

Describe 'New-LabSecurityGroup' {
    BeforeEach {
        Mock Ensure-Module {}
        Mock Write-LabLog {}
        Mock Resolve-OU -MockWith { param($Name) "OU=$Name,OU=Company,DC=corp,DC=local" }
        Mock New-ADGroup {}
        Mock Get-ADGroup -MockWith { [pscustomobject]@{ Name='GG_IT_All'; DistinguishedName='CN=GG_IT_All,OU=IT,OU=Company,DC=corp,DC=local'; Description='Old'; GroupScope='Global' } }
        Mock Set-ADGroup {}
    }

    It 'updates description when it changes' {
        New-LabSecurityGroup -Name 'GG_IT_All' -OU 'IT' -Scope 'Global' -Description 'New description' | Out-Null
        Assert-MockCalled -CommandName Set-ADGroup -ParameterFilter { $Description -eq 'New description' } -Times 1
    }
}

Describe 'New-LabUser' {
    BeforeEach {
        Mock Ensure-Module {}
        Mock Write-LabLog {}
        Mock Add-LabUserToGroup {}
        Mock Enable-ADAccount {}
        Mock Set-ADAccountPassword {}
        Mock Set-ADUser {}
        Mock New-ADUser {}
        Mock Get-ADPrincipalGroupMembership -MockWith { @() }
    }

    It 'creates a new user and adds specified groups' {
        $script:userCall = 0
        Mock Get-ADUser -MockWith {
            $script:userCall++
            if ($script:userCall -eq 1) { return $null }
            return [pscustomobject]@{ SamAccountName='jdoe'; PasswordLastSet=(Get-Date); Enabled=$true }
        }

        New-LabUser -GivenName 'John' -Surname 'Doe' -SamAccountName 'jdoe' -OU 'IT' -TempPassword (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force) -AddToGroups 'GG_IT_All' | Out-Null

        Assert-MockCalled -CommandName New-ADUser -Times 1
        Assert-MockCalled -CommandName Add-LabUserToGroup -Times 1
        Assert-MockCalled -CommandName Set-ADAccountPassword -Times 0
    }

    It 'updates existing user without re-adding groups already present' {
        $userObject = [pscustomobject]@{
            SamAccountName     = 'jdoe'
            PasswordLastSet    = Get-Date
            Enabled            = $true
            GivenName          = 'John'
            Surname            = 'Doe'
            DisplayName        = 'John Doe'
            UserPrincipalName  = 'jdoe@corp.local'
            EmailAddress       = 'jdoe@corp.local'
            Title              = 'Analyst'
            Department         = 'IT'
        }
        $script:existingCall = 0
        Mock Get-ADUser -MockWith {
            $script:existingCall++
            return $userObject
        }

        Mock Get-ADPrincipalGroupMembership -MockWith { [pscustomobject]@{ SamAccountName='GG_IT_All'; Name='GG_IT_All' } }

        Mock Add-LabUserToGroup -MockWith {
            throw 'Should not be called when group is already assigned'
        }

        New-LabUser -GivenName 'John' -Surname 'Doe' -SamAccountName 'jdoe' -OU 'IT' -TempPassword (ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force) -AddToGroups 'GG_IT_All' | Out-Null

        Assert-MockCalled -CommandName Set-ADUser -Times 0
    }
}

Describe 'Disable-LabUser' {
    BeforeEach {
        Mock Ensure-Module {}
        Mock Write-LabLog {}
        Mock Set-ADUser {}
        Mock Disable-ADAccount {}
        Mock Get-ADUser -MockWith { [pscustomobject]@{ SamAccountName='jdoe'; Enabled=$true; SmartcardLogonRequired=$false } }
    }

    It 'disables a user exactly once' {
        Disable-LabUser -SamAccountName 'jdoe' | Out-Null
        Assert-MockCalled -CommandName Disable-ADAccount -Times 1
    }
}
