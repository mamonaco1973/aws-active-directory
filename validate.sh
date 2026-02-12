#!/bin/bash
# ==============================================================================
# validate.sh - AWS Managed AD Quick Start Validation
# ------------------------------------------------------------------------------
# Purpose:
#   - Validates Directory Service and EC2 instances.
#   - Prints quick-start endpoints.
#
# Scope:
#   - Checks:
#       - Managed Microsoft AD directory
#       - Windows instance
#       - Linux instance
#   - Prints public DNS names and domain information.
#
# Requirements:
#   - AWS CLI installed and authenticated.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-2"

DIRECTORY_NAME="mcloud.mikecloud.com"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
get_public_dns_by_name_tag() {
  local name_tag="$1"

  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${name_tag}" \
    --query "Reservations[].Instances[].PublicDnsName" \
    --output text | xargs
}

get_directory_info() {
  aws ds describe-directories \
    --query "DirectoryDescriptions[?Name=='${DIRECTORY_NAME}'].[DirectoryId,Stage,DnsIpAddrs]" \
    --output text
}

# ------------------------------------------------------------------------------
# Lookups
# ------------------------------------------------------------------------------
windows_dns="$(get_public_dns_by_name_tag "windows-ad-instance")"
linux_dns="$(get_public_dns_by_name_tag "linux-ad-instance")"

directory_info="$(get_directory_info || true)"

# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo "AWS Managed Microsoft AD - Validation Output"
echo "============================================================================"
echo ""

if [ -n "${directory_info}" ]; then
  echo "NOTE: Directory Info:"
  echo "      ${directory_info}"
else
  echo "WARN: Directory ${DIRECTORY_NAME} not found"
fi

echo ""

if [ -n "${windows_dns}" ] && [ "${windows_dns}" != "None" ]; then
  echo "NOTE: Windows RDP Host FQDN: ${windows_dns}"
else
  echo "WARN: windows-ad-instance not found or no public DNS"
fi

if [ -n "${linux_dns}" ] && [ "${linux_dns}" != "None" ]; then
  echo "NOTE: Linux SSH Host FQDN:  ${linux_dns}"
else
  echo "WARN: linux-ad-instance not found or no public DNS"
fi

echo ""
echo "NOTE: Validation complete."
echo ""
