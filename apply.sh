#!/bin/bash

# -------------------------
# Step 0: Set AWS region
# -------------------------

export AWS_DEFAULT_REGION=us-east-1  # Required so AWS CLI/Terraform know where to operate

# --------------------------------------
# Step 1: Run preflight environment check
# --------------------------------------
./check_env.sh  # This should validate CLI setup, credentials, and required binaries
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1  # 🚨 Abort if check_env.sh fails — nothing should run without a valid env
fi
set -e

# -------------------------------------
# Step 2: Build Phase 1 - AD Deployment
# -------------------------------------
cd 01-directory  # Enter the Terraform directory for AD setup

terraform init  # Initialize Terraform — installs providers, sets up backend
terraform apply -auto-approve  # 🚀 Launch AD resources (Managed Microsoft AD or Simple AD)

cd ..  # Go back to root directory

# -------------------------------------------------
# Step 3: Get the Directory ID for mcloud.mikecloud.com
# -------------------------------------------------
directory_id=$(aws ds describe-directories \
  --region us-east-1 \
  --query "DirectoryDescriptions[?Name=='mcloud.mikecloud.com'].DirectoryId" \
  --output text)  # 🔍 Extract the directory_id dynamically for use in next Terraform phase

# ------------------------------------------
# Step 4: Build Phase 2 - EC2 Server Launch
# ------------------------------------------
cd 02-servers  # Enter the Terraform folder for EC2 instances

terraform init  # Re-initialize in this directory
terraform apply -var="directory_id=$directory_id"  -auto-approve  # ⚙️ Pass directory ID into the EC2 provisioning module

cd ..  # Return to root

# -------------------------
# Step 5: Run Branding Script
# -------------------------
echo "NOTE: Branding the Workspaces."
./brand.sh  # 🖼️ Apply custom branding (logos, etc.) to WorkSpaces client portals

# --------------------------------------------
# Step 6: Run validate script
# --------------------------------------------

./validate.sh


