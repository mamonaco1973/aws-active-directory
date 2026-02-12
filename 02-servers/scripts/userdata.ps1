<powershell>
$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$Log = 'C:\ProgramData\userdata.log'
New-Item -Path $Log -ItemType File -Force | Out-Null
Start-Transcript -Path $Log -Append -Force

try {
    Write-Output "Starting PowerShell user-data at $(Get-Date -Format o)"

    # ----------------------------------------------------------------------
    # Install AD Management Features (safe to re-run)
    # ----------------------------------------------------------------------
    Write-Output "Installing AD management Windows features"
    Install-WindowsFeature -Name `
        GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server | Out-Null

    # ----------------------------------------------------------------------
    # Install AWS CLI v2 (idempotent)
    # ----------------------------------------------------------------------
    $AwsExe = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'

    if (-not (Test-Path $AwsExe)) {
        Write-Output "Installing AWS CLI v2"
        Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi `
            -OutFile C:\Users\Administrator\AWSCLIV2.msi

        Start-Process "msiexec" `
            -ArgumentList "/i C:\Users\Administrator\AWSCLIV2.msi /qn" `
            -Wait -NoNewWindow
    }
    else {
        Write-Output "AWS CLI already installed"
    }

    $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"

    # ----------------------------------------------------------------------
    # Retrieve Domain Credentials
    # ----------------------------------------------------------------------
    Write-Output "Retrieving domain credentials"
    $secretValue  = aws secretsmanager get-secret-value `
        --secret-id ${admin_secret} `
        --query SecretString `
        --output text

    $secretObject = $secretValue | ConvertFrom-Json
    $password     = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force
    $cred         = New-Object System.Management.Automation.PSCredential `
        ($secretObject.username, $password)

    # ----------------------------------------------------------------------
    # Domain Join (idempotent)
    # ----------------------------------------------------------------------
    $didJoin = $false
    $cs = Get-CimInstance Win32_ComputerSystem

    if ($cs.PartOfDomain -and $cs.Domain -ieq "${domain_fqdn}") {
        Write-Output "System already joined to ${domain_fqdn}"
    }
    else {
        Write-Output "Joining domain ${domain_fqdn}"
        Add-Computer -DomainName "${domain_fqdn}" `
            -Credential $cred `
            -Force `
            -OUPath "${computers_ou}"
        $didJoin = $true
    }

    # ----------------------------------------------------------------------
    # AD Group Helper (idempotent, no Get-ADGroup)
    # ----------------------------------------------------------------------
    function New-AdGroupIfMissing {
        param ($Name, $Gid)

        try {
            New-ADGroup -Name $Name `
                -GroupCategory Security `
                -GroupScope Universal `
                -Credential $cred `
                -OtherAttributes @{ gidNumber = $Gid } `
                -ErrorAction Stop | Out-Null

            Write-Output "Created group: $Name"
        }
        catch {
            if ($_.Exception.Message -match "already exists") {
                Write-Output "Group already exists: $Name"
            }
            else { throw }
        }
    }

    Write-Output "Ensuring AD groups exist"

    New-AdGroupIfMissing "mcloud-users"  "10001"
    New-AdGroupIfMissing "india"        "10002"
    New-AdGroupIfMissing "us"           "10003"
    New-AdGroupIfMissing "linux-admins" "10004"

    # ----------------------------------------------------------------------
    # AD User Helper (idempotent)
    # ----------------------------------------------------------------------
    $global:uidCounter = 10000

    function New-AdUserFromSecretIfMissing {
        param (
            $SecretId,
            $GivenName,
            $Surname,
            $DisplayName,
            $Email,
            $Username,
            $Groups
        )

        $global:uidCounter++
        $uidNumber = $global:uidCounter

        $secretValue  = aws secretsmanager get-secret-value `
            --secret-id $SecretId `
            --query SecretString `
            --output text

        $secretObject = $secretValue | ConvertFrom-Json
        $userPassword = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force

        try {
            New-ADUser `
                -Name $Username `
                -GivenName $GivenName `
                -Surname $Surname `
                -DisplayName $DisplayName `
                -EmailAddress $Email `
                -UserPrincipalName "$Username@${domain_fqdn}" `
                -SamAccountName $Username `
                -AccountPassword $userPassword `
                -Enabled $true `
                -Credential $cred `
                -PasswordNeverExpires $true `
                -OtherAttributes @{ gidNumber='10001'; uidNumber=$uidNumber } `
                -ErrorAction Stop | Out-Null

            Write-Output "Created user: $Username"
        }
        catch {
            if ($_.Exception.Message -match "already exists") {
                Write-Output "User already exists: $Username"
            }
            else { throw }
        }

        foreach ($group in $Groups) {
            try {
                Add-ADGroupMember -Identity $group `
                    -Members $Username `
                    -Credential $cred `
                    -ErrorAction Stop
            }
            catch {
                if ($_.Exception.Message -match "already a member") {
                    Write-Output "$Username already in $group"
                }
                else { throw }
            }
        }
    }

    Write-Output "Ensuring AD users exist"

    New-AdUserFromSecretIfMissing "jsmith_ad_credentials_ds" "John"  "Smith" "John Smith" `
        "jsmith@mikecloud.com" "jsmith" @("mcloud-users","us","linux-admins")

    New-AdUserFromSecretIfMissing "edavis_ad_credentials_ds" "Emily" "Davis" "Emily Davis" `
        "edavis@mikecloud.com" "edavis" @("mcloud-users","us")

    New-AdUserFromSecretIfMissing "rpatel_ad_credentials_ds" "Raj"   "Patel" "Raj Patel" `
        "rpatel@mikecloud.com" "rpatel" @("mcloud-users","india","linux-admins")

    New-AdUserFromSecretIfMissing "akumar_ad_credentials_ds" "Amit"  "Kumar" "Amit Kumar" `
        "akumar@mikecloud.com" "akumar" @("mcloud-users","india")

    # ----------------------------------------------------------------------
    # RDP Access (safe to re-run)
    # ----------------------------------------------------------------------
    Write-Output "Ensuring RDP access for mcloud-users"

    try {
        Add-LocalGroupMember -Group "Remote Desktop Users" `
            -Member "MCLOUD\mcloud-users" `
            -ErrorAction Stop
    }
    catch {
        if ($_.Exception.Message -match "already a member") {
            Write-Output "mcloud-users already in Remote Desktop Users"
        }
        else { throw }
    }

    # ----------------------------------------------------------------------
    # Reboot only if domain join occurred
    # ----------------------------------------------------------------------
    if ($didJoin) {
        Write-Output "Rebooting to finalize domain join"
        shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1
    }
    else {
        Write-Output "No reboot required"
    }
}
finally {
    Write-Output "User-data finishing at $(Get-Date -Format o)"
    Stop-Transcript | Out-Null
}
</powershell>
