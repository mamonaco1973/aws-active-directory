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

# echo "NOTE: Workspaces Registration Code is '$regcode'"

