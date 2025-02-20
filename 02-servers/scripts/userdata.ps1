<powershell>

# Install AD Components

Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server

# Download and install AWS CLI

$ProgressPreference = 'SilentlyContinue'

Write-Host "Installing AWS CLI..."
Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile C:\Users\Administrator\AWSCLIV2.msi
Start-Process "msiexec" -argumentlist "/i C:\Users\Administrator\AWSCLIV2.msi /qn" -Wait -NoNewWindow

# Add comment
  
</powershell>