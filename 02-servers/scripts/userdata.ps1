<powershell>
$ErrorActionPreference = 'Stop'
$ProgressPreference   = 'SilentlyContinue'

$Log = 'C:\ProgramData\userdata.log'
New-Item -Path $Log -ItemType File -Force | Out-Null
Start-Transcript -Path $Log -Append -Force

try {
    Write-Output "Starting PowerShell user-data at $(Get-Date -Format o)"

    # Install AD management features
    Install-WindowsFeature -Name `
        GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server

    # Install AWS CLI v2
    Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi `
        -OutFile C:\Users\Administrator\AWSCLIV2.msi

    Start-Process "msiexec" `
        -ArgumentList "/i C:\Users\Administrator\AWSCLIV2.msi /qn" `
        -Wait -NoNewWindow

    $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"

    # Retrieve domain credentials
    $secretValue  = aws secretsmanager get-secret-value `
        --secret-id ${admin_secret} `
        --query SecretString `
        --output text

    $secretObject = $secretValue | ConvertFrom-Json
    $password     = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force
    $cred         = New-Object System.Management.Automation.PSCredential `
        ($secretObject.username, $password)

    # Join domain
    Add-Computer -DomainName "${domain_fqdn}" `
        -Credential $cred `
        -Force `
        -OUPath "${computers_ou}"

    # Create AD groups
    New-ADGroup -Name "mcloud-users" -GroupCategory Security -GroupScope Universal `
        -Credential $cred -OtherAttributes @{gidNumber='10001'}

    New-ADGroup -Name "india" -GroupCategory Security -GroupScope Universal `
        -Credential $cred -OtherAttributes @{gidNumber='10002'}

    New-ADGroup -Name "us" -GroupCategory Security -GroupScope Universal `
        -Credential $cred -OtherAttributes @{gidNumber='10003'}

    New-ADGroup -Name "linux-admins" -GroupCategory Security -GroupScope Universal `
        -Credential $cred -OtherAttributes @{gidNumber='10004'}

    # UID counter
    $global:uidCounter = 10000

    function New-ADUserFromSecret {
        param (
            [string]$SecretId,
            [string]$GivenName,
            [string]$Surname,
            [string]$DisplayName,
            [string]$Email,
            [string]$Username,
            [array]$Groups
        )

        $global:uidCounter++
        $uidNumber = $global:uidCounter

        $secretValue  = aws secretsmanager get-secret-value `
            --secret-id $SecretId `
            --query SecretString `
            --output text

        $secretObject = $secretValue | ConvertFrom-Json
        $password     = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force

        New-ADUser `
            -Name $Username `
            -GivenName $GivenName `
            -Surname $Surname `
            -DisplayName $DisplayName `
            -EmailAddress $Email `
            -UserPrincipalName "$Username@${domain_fqdn}" `
            -SamAccountName $Username `
            -AccountPassword $password `
            -Enabled $true `
            -Credential $cred `
            -PasswordNeverExpires $true `
            -OtherAttributes @{gidNumber='10001'; uidNumber=$uidNumber}

        foreach ($group in $Groups) {
            Add-ADGroupMember -Identity $group -Members $Username -Credential $cred
        }
    }

    # Create users
    New-ADUserFromSecret "jsmith_ad_credentials_ds" "John" "Smith" "John Smith" `
        "jsmith@mikecloud.com" "jsmith" @("mcloud-users","us","linux-admins")

    New-ADUserFromSecret "edavis_ad_credentials_ds" "Emily" "Davis" "Emily Davis" `
        "edavis@mikecloud.com" "edavis" @("mcloud-users","us")

    New-ADUserFromSecret "rpatel_ad_credentials_ds" "Raj" "Patel" "Raj Patel" `
        "rpatel@mikecloud.com" "rpatel" @("mcloud-users","india","linux-admins")

    New-ADUserFromSecret "akumar_ad_credentials_ds" "Amit" "Kumar" "Amit Kumar" `
        "akumar@mikecloud.com" "akumar" @("mcloud-users","india")

    # RDP group assignment (with retry)
    $domainGroup = "MCLOUD\mcloud-users"
    $maxRetries  = 10
    $retryDelay  = 30

    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Add-LocalGroupMember -Group "Remote Desktop Users" `
                -Member $domainGroup -ErrorAction Stop
            break
        } catch {
            Start-Sleep -Seconds $retryDelay
        }
    }

    shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1
}
finally {
    Stop-Transcript | Out-Null
}
</powershell>
