#!/bin/bash
# ==============================================================================
# File: destroy.sh
# ------------------------------------------------------------------------------
# Purpose:
#   Tear down the full stack in two phases:
#     1) Destroy EC2 servers
#     2) Force-delete Secrets Manager entries
#     3) Destroy AWS Managed Microsoft AD
#
# Notes:
#   - Script fails immediately on any error.
#   - Execution order matters (servers must be removed first).
#   - Secrets are force-deleted to avoid recovery window delays.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Global configuration
# ------------------------------------------------------------------------------

export AWS_DEFAULT_REGION="us-east-2"

# ------------------------------------------------------------------------------
# Phase 1: Destroy EC2 Servers
# ------------------------------------------------------------------------------

cd 02-servers

terraform init
terraform destroy -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Phase 2: Force Delete Secrets
# ------------------------------------------------------------------------------

aws secretsmanager delete-secret \
  --secret-id "akumar_ad_credentials_ds" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "jsmith_ad_credentials_ds" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "edavis_ad_credentials_ds" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "rpatel_ad_credentials_ds" \
  --force-delete-without-recovery

aws secretsmanager delete-secret \
  --secret-id "admin_ad_credentials_ds" \
  --force-delete-without-recovery

# ------------------------------------------------------------------------------
# Phase 3: Destroy Directory Service
# ------------------------------------------------------------------------------

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..


