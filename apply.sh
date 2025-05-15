#!/bin/bash

# Check to make sure we can build

export AWS_DEFAULT_REGION=us-east-1

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Build Phase 1 - Create the AD instance

cd 01-directory

terraform init
terraform apply -auto-approve

cd ..

directory_id=$(aws ds describe-directories \
  --region us-east-1 \
  --query "DirectoryDescriptions[?Name=='mcloud.mikecloud.com'].DirectoryId" \
  --output text)

# Build Phase 2 - Create EC2 Instances

cd 02-servers

terraform init
terraform apply -var="directory_id=$directory_id"  -auto-approve

cd .. 

regcode=$(aws workspaces describe-workspace-directories \
  --region us-east-1 \
  --query "Directories[?DirectoryName=='mcloud.mikecloud.com'].RegistrationCode" \
  --output text)

echo "NOTE: Branding the Workspaces."
./brand.sh

echo "NOTE: Workspaces Registration Code is '$regcode'"
echo "NOTE: Workspace web client url is 'https://us-east-1.webclient.amazonworkspaces.com/login'"

windows_dns_name=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=windows-ad-instance" \
  --query "Reservations[*].Instances[*].PrivateDnsName" \
  --output text)
echo "NOTE: Private DNS name for Windows Server is '$windows_dns_name'"

linux_dns_name=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=linux-ad-instance" \
  --query "Reservations[*].Instances[*].PrivateDnsName" \
  --output text)

echo "NOTE: Private DNS name for Linux Server is '$linux_dns_name'"


