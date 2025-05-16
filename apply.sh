#!/bin/bash

# Check to make sure we can build

export AWS_DEFAULT_REGION=us-east-2  # Required so AWS CLI/Terraform know where to operate

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

# Build Phase 2 - Create EC2 Instances

cd 02-servers

terraform init
terraform apply -auto-approve

cd .. 

