<powershell>

# Install AD Components

$ProgressPreference = 'SilentlyContinue'
Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server

# Download and install AWS CLI

Write-Host "Installing AWS CLI..."
Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile C:\Users\Administrator\AWSCLIV2.msi
Start-Process "msiexec" -argumentlist "/i C:\Users\Administrator\AWSCLIV2.msi /qn" -Wait -NoNewWindow
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"

# Join instance to active directory

$secretValue = aws secretsmanager get-secret-value --secret-id ${admin_secret} --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password = $secretObject.password | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $secretObject.username, $password
Add-Computer -DomainName "${domain_fqdn}" -Credential $cred -Force -OUPath "${computers_ou}"

# Create some users and groups for testing

New-ADGroup -Name "mcloud-users" -GroupCategory Security -GroupScope Universal -credential $cred -OtherAttributes @{gidNumber='10001'}
New-ADGroup -Name "india" -GroupCategory Security -GroupScope Universal -credential $cred -OtherAttributes @{gidNumber='10002'}
New-ADGroup -Name "us" -GroupCategory Security -GroupScope Universal -credential $cred -OtherAttributes @{gidNumber='10003'}
New-ADGroup -Name "linux-admins" -GroupCategory Security -GroupScope Universal -credential $cred -OtherAttributes @{gidNumber='10004'}

# Create John Smith

$secretValue = aws secretsmanager get-secret-value --secret-id jsmith_ad_credentials --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password = $secretObject.password | ConvertTo-SecureString -asPlainText -Force

New-ADUser -Name "jsmith" `
    -GivenName "John" `
    -Surname "Smith" `
    -DisplayName "John Smith" `
    -EmailAddress "jsmith@mikecloud.com" `
    -UserPrincipalName "jsmith@mikecloud.com" `
    -SamAccountName "jsmith" `
    -AccountPassword $password `
    -Enabled $true `
    -Credential $cred `
    -PasswordNeverExpires $true `
    -OtherAttributes @{gidNumber='10001'; uidNumber='10001'}

Add-ADGroupMember -Identity "mcloud-users" -Members jsmith -credential $cred
Add-ADGroupMember -Identity "us" -Members jsmith -credential $cred
Add-ADGroupMember -Identity "linux-admins" -Members jsmith -credential $cred

# Create Emily Davis

$secretValue = aws secretsmanager get-secret-value --secret-id edavis_ad_credentials --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password = $secretObject.password | ConvertTo-SecureString -asPlainText -Force

New-ADUser -Name "edavis" `
    -GivenName "Emily" `
    -Surname "Davis" `
    -DisplayName "Emily Davis" `
    -EmailAddress "edavis@mikecloud.com" `
    -UserPrincipalName "edavis@mikecloud.com" `
    -SamAccountName "edavis" `
    -AccountPassword $password `
    -Enabled $true `
    -Credential $cred `
    -PasswordNeverExpires $true `
    -OtherAttributes @{gidNumber='10001'; uidNumber='10002'}

Add-ADGroupMember -Identity "mcloud-users" -Members edavis -credential $cred
Add-ADGroupMember -Identity "us" -Members edavis -credential $cred

# Create Raj Patel

$secretValue = aws secretsmanager get-secret-value --secret-id rpatel_ad_credentials --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password = $secretObject.password | ConvertTo-SecureString -asPlainText -Force

New-ADUser -Name "rpatel" `
    -GivenName "Raj" `
    -Surname "Patel" `
    -DisplayName "Raj Patel" `
    -EmailAddress "rpatel@mikecloud.com" `
    -UserPrincipalName "rpatel@mikecloud.com" `
    -SamAccountName "rpatel" `
    -AccountPassword $password `
    -Enabled $true `
    -Credential $cred `
    -PasswordNeverExpires $true `
    -OtherAttributes @{gidNumber='10001'; uidNumber='10003'}

Add-ADGroupMember -Identity "mcloud-users" -Members rpatel -credential $cred
Add-ADGroupMember -Identity "india" -Members rpatel -credential $cred
Add-ADGroupMember -Identity "linux-admins" -Members rpatel -credential $cred

# Create Amit Kumar

$secretValue = aws secretsmanager get-secret-value --secret-id akumar_ad_credentials --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password = $secretObject.password | ConvertTo-SecureString -asPlainText -Force

New-ADUser -Name "akumar" `
    -GivenName "Amit" `
    -Surname "Kumar" `
    -DisplayName "Amit Kumar" `
    -EmailAddress "akumar@mikecloud.com" `
    -UserPrincipalName "akumar@mikecloud.com" `
    -SamAccountName "akumar" `
    -AccountPassword $password `
    -Enabled $true `
    -Credential $cred `
    -PasswordNeverExpires $true `
    -OtherAttributes @{gidNumber='10001'; uidNumber='10004'}

Add-ADGroupMember -Identity "mcloud-users" -Members akumar -credential $cred
Add-ADGroupMember -Identity "india" -Members akumar -credential $cred

# Grant all users RDP access to this machine

Add-LocalGroupMember -Group "Remote Desktop Users" -Member mcloud-users

# Retrieve the instance ID from AWS EC2 metadata using IMDSv2 (Instance Metadata Service Version 2)
$token = Invoke-RestMethod -Method Put -Uri "http://169.254.169.254/latest/api/token" -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }
$instanceId = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/instance-id" -Headers @{ "X-aws-ec2-metadata-token" = $token }

# Retrieve IAM instance profile association ID for the current EC2 instance
$associationId = aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instanceId" --query "IamInstanceProfileAssociations[0].AssociationId" --output text

# Reassign the instance IAM profile to a less privileged profile
$profileName = "EC2SSMProfile"
aws ec2 replace-iam-instance-profile-association --iam-instance-profile Name=$profileName --association-id $associationId

# Shutdown and reboot server to finalize domain join

shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1

</powershell>