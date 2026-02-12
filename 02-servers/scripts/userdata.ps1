<powershell>
$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$Log = 'C:\ProgramData\userdata.log'
New-Item -Path $Log -ItemType File -Force | Out-Null
Start-Transcript -Path $Log -Append -Force

try {
    Write-Host "Starting PowerShell user-data at $(Get-Date -Format o)"

    Write-Host "Installing AD management Windows features"
    Install-WindowsFeature -Name `
        GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server

    Write-Host "Downloading AWS CLI v2 MSI"
    $msi = 'C:\Users\Administrator\AWSCLIV2.msi'
    if (-not (Test-Path $msi)) {
        Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile $msi
    }

    Write-Host "Installing AWS CLI v2 MSI"
    Start-Process "msiexec" -ArgumentList "/i $msi /qn" -Wait -NoNewWindow

    $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
    Write-Host "AWS CLI path: $((Get-Command aws -ErrorAction SilentlyContinue).Source)"

    Write-Host "Retrieving domain join credentials from Secrets Manager"
    $secretValue  = aws secretsmanager get-secret-value `
        --secret-id ${admin_secret} `
        --query SecretString `
        --output text

    $secretObject = $secretValue | ConvertFrom-Json
    $securePassword = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential `
        ($secretObject.username, $securePassword)

    # Domain join (skip if already joined)
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.PartOfDomain -and ($cs.Domain -ieq "${domain_fqdn}")) {
        Write-Host "Already joined to ${domain_fqdn}"
    } else {
        Write-Host "Joining AD domain ${domain_fqdn}"
        Add-Computer -DomainName "${domain_fqdn}" -Credential $cred -Force `
            -OUPath "${computers_ou}"
        Write-Host "Domain join command completed"
    }

    Write-Host "Loading ActiveDirectory module"
    Import-Module ActiveDirectory

    function New-ADGroupIfMissing {
        param(
            [string]$Name,
            [string]$GidNumber
        )

        if (Get-ADGroup -Identity $Name -ErrorAction SilentlyContinue) {
            Write-Host "Group exists: $Name"
            return
        }

        Write-Host "Creating group: $Name"
        New-ADGroup -Name $Name -GroupCategory Security -GroupScope Universal `
            -Credential $cred -OtherAttributes @{gidNumber=$GidNumber}
    }

    Write-Host "Creating AD groups (idempotent)"
    New-ADGroupIfMissing -Name "mcloud-users" -GidNumber "10001"
    New-ADGroupIfMissing -Name "india"       -GidNumber "10002"
    New-ADGroupIfMissing -Name "us"          -GidNumber "10003"
    New-ADGroupIfMissing -Name "linux-admins" -GidNumber "10004"

    $global:uidCounter = 10000

    function New-ADUserFromSecret {
        param(
            [string]$SecretId,
            [string]$GivenName,
            [string]$Surname,
            [string]$DisplayName,
            [string]$Email,
            [string]$Username,
            [array]$Groups
        )

        $user = Get-ADUser -Identity $Username -ErrorAction SilentlyContinue

        if (-not $user) {
            $global:uidCounter++
            $uidNumber = $global:uidCounter

            Write-Host "User $Username : retrieving secret $SecretId"
            $sv = aws secretsmanager get-secret-value `
                --secret-id $SecretId `
                --query SecretString `
                --output text

            $so = $sv | ConvertFrom-Json
            $userSecurePassword = $so.password | ConvertTo-SecureString `
                -AsPlainText -Force

            Write-Host "User $Username : creating AD user"
            New-ADUser `
                -Name $Username `
                -GivenName $GivenName `
                -Surname $Surname `
                -DisplayName $DisplayName `
                -EmailAddress $Email `
                -UserPrincipalName "$Username@${domain_fqdn}" `
                -SamAccountName $Username `
                -AccountPassword $userSecurePassword `
                -Enabled $true `
                -Credential $cred `
                -PasswordNeverExpires $true `
                -OtherAttributes @{gidNumber='10001'; uidNumber=$uidNumber}

            $user = Get-ADUser -Identity $Username
        } else {
            Write-Host "User exists: $Username"
        }

        $currentGroups = @()
        try {
            $currentGroups =
                (Get-ADPrincipalGroupMembership -Identity $Username `
                 | Select-Object -ExpandProperty Name)
        } catch {
            $currentGroups = @()
        }

        foreach ($group in $Groups) {
            if ($currentGroups -contains $group) {
                Write-Host "User $Username already in group $group"
            } else {
                Write-Host "Adding $Username to group $group"
                Add-ADGroupMember -Identity $group -Members $Username `
                    -Credential $cred
            }
        }

        Write-Host "User $Username : complete"
    }

    Write-Host "Creating AD users (idempotent)"
    New-ADUserFromSecret "jsmith_ad_credentials_ds" "John" "Smith" "John Smith" `
        "jsmith@mikecloud.com" "jsmith" @("mcloud-users","us","linux-admins")

    New-ADUserFromSecret "edavis_ad_credentials_ds" "Emily" "Davis" "Emily Davis" `
        "edavis@mikecloud.com" "edavis" @("mcloud-users","us")

    New-ADUserFromSecret "rpatel_ad_credentials_ds" "Raj" "Patel" "Raj Patel" `
        "rpatel@mikecloud.com" "rpatel" @("mcloud-users","india","linux-admins")

    New-ADUserFromSecret "akumar_ad_credentials_ds" "Amit" "Kumar" "Amit Kumar" `
        "akumar@mikecloud.com" "akumar" @("mcloud-users","india")

    Write-Host "Granting RDP access to domain group (idempotent)"
    $domainGroup = "MCLOUD\mcloud-users"
    $localGroup  = "Remote Desktop Users"

    $already = Get-LocalGroupMember -Group $localGroup -ErrorAction SilentlyContinue `
        | Where-Object { $_.Name -ieq $domainGroup }

    if ($already) {
        Write-Host "$domainGroup already in $localGroup"
    } else {
        $maxRetries = 10
        $retryDelay = 30

        for ($i = 1; $i -le $maxRetries; $i++) {
            try {
                Write-Host "Attempt $i : Add-LocalGroupMember $domainGroup"
                Add-LocalGroupMember -Group $localGroup -Member $domainGroup `
                    -ErrorAction Stop
                Write-Host "SUCCESS: Added $domainGroup to $localGroup"
                break
            } catch {
                Write-Host "WARN: Attempt $i failed - waiting $retryDelay seconds"
                Start-Sleep -Seconds $retryDelay
            }
        }
    }

    Write-Host "Rebooting to finalize domain join and apply group policy"
    shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1
}
finally {
    Write-Host "User-data finishing at $(Get-Date -Format o)"
    Stop-Transcript | Out-Null
}
</powershell>
