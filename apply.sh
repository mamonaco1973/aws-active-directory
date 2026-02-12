#!/bin/bash
# ==============================================================================
# File: apply.sh
# ------------------------------------------------------------------------------
# Purpose:
#   Deploy the full stack in two phases:
#     1) AWS Managed Microsoft AD (Directory Service)
#     2) EC2 servers that depend on the directory
#
# Notes:
#   - Script fails immediately on any error.
#   - AWS_DEFAULT_REGION must be set for AWS CLI and Terraform.
#   - Execution order matters (servers depend on directory).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Global configuration
# ------------------------------------------------------------------------------

export AWS_DEFAULT_REGION="us-east-2"

# ------------------------------------------------------------------------------
# Pre-flight environment validation
# ------------------------------------------------------------------------------

./check_env.sh

# ------------------------------------------------------------------------------
# Phase 1: Directory Service
# ------------------------------------------------------------------------------

echo "NOTE: Deploying Directory Service..."

cd 01-directory

terraform init
terraform apply -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: EC2 Servers
# ------------------------------------------------------------------------------

echo "NOTE: Deploying Test EC2 instances..."

cd 02-servers

terraform init
terraform apply -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Call Validation
# ------------------------------------------------------------------------------

./validate.sh

# ------------------------------------------------------------------------------
# Completed
# ------------------------------------------------------------------------------

echo "NOTE: Deployment complete."
