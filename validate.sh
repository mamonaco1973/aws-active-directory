#!/bin/bash

# -------------------------
# Step 0: Set AWS region
# -------------------------

export AWS_DEFAULT_REGION=us-east-1  # Required so AWS CLI/Terraform know where to operate

# --------------------------------------
# Step 1: Retrieve WorkSpaces Registration Code
# -------------------------------------------------
regcode=$(aws workspaces describe-workspace-directories \
  --region us-east-1 \
  --query "Directories[?DirectoryName=='mcloud.mikecloud.com'].RegistrationCode" \
  --output text)  # 🔐 This code is needed to register WorkSpaces clients

# --------------------------------------------
# Step 2: Output Registration Code and URL
# --------------------------------------------
echo "NOTE: Workspaces Registration Code is '$regcode'"
echo "NOTE: Workspace web client url is 'https://us-east-1.webclient.amazonworkspaces.com/login'"

# ------------------------------------------------------------
# Step 3: Fetch EC2 Private DNS Name for Windows AD Instance
# ------------------------------------------------------------
windows_dns_name=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=windows-ad-instance" \
  --query "Reservations[*].Instances[*].PrivateDnsName" \
  --output text)  # 🛰️ Pull internal DNS name — useful for joining domain, troubleshooting

echo "NOTE: Private DNS name for Windows Server is '$windows_dns_name'"

# ----------------------------------------------------------
# Step 4: Fetch EC2 Private DNS Name for Linux AD Instance
# ----------------------------------------------------------
linux_dns_name=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=linux-ad-instance" \
  --query "Reservations[*].Instances[*].PrivateDnsName" \
  --output text)  # 🛰️ Same as above but for Linux node

echo "NOTE: Private DNS name for Linux Server is '$linux_dns_name'"
