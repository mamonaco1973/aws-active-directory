#!/bin/bash
# ==============================================================================
# validate.sh - AWS Managed AD Quick Start Validation
# ------------------------------------------------------------------------------
# PURPOSE:
#   - Validate Directory Service and EC2 instances
#   - Print quick-start endpoints
#
# SCOPE:
#   - Checks:
#       - Managed Microsoft AD directory
#       - Windows instance
#       - Linux instance
#   - Prints public DNS names and directory details
#
# REQUIREMENTS:
#   - AWS CLI installed and authenticated
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

get_directory_fields() {
  # Output (tab-separated):
  #   <DirectoryId> <Stage> <DnsIp1> <DnsIp2> ...
  aws ds describe-directories \
    --query "DirectoryDescriptions[?Name=='${DIRECTORY_NAME}'].[DirectoryId,Stage,DnsIpAddrs] | [0]" \
    --output text
}

print_directory_info() {
  local fields
  fields="$(get_directory_fields || true)"

  if [ -z "${fields}" ] || [ "${fields}" = "None" ]; then
    echo "WARN: Directory '${DIRECTORY_NAME}' not found"
    return 0
  fi

  local dir_id stage dns_ips
  dir_id="$(awk '{print $1}' <<<"${fields}")"
  stage="$(awk '{print $2}' <<<"${fields}")"
  dns_ips="$(cut -f3- <<<"${fields}" | xargs)"

  echo "NOTE: Directory Info:"
  echo "      Name : ${DIRECTORY_NAME}"
  echo "      ID   : ${dir_id}"
  echo "      Stage: ${stage}"
  echo "      DNS  : ${dns_ips}"
}

# ------------------------------------------------------------------------------
# Lookups
# ------------------------------------------------------------------------------
windows_dns="$(get_public_dns_by_name_tag "windows-ad-instance")"
linux_dns="$(get_public_dns_by_name_tag "linux-ad-instance")"

# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo "AWS Managed Microsoft AD - Validation Output"
echo "============================================================================"
echo ""

print_directory_info
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
