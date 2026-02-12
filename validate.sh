#!/bin/bash
# ==============================================================================
# validate.sh - AWS Managed AD Quick Start Validation
# ==============================================================================

set -euo pipefail

export AWS_DEFAULT_REGION="us-east-2"
DIRECTORY_NAME="mcloud.mikecloud.com"

get_public_dns_by_name_tag() {
  local name_tag="$1"

  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${name_tag}" \
    --query "Reservations[].Instances[].PublicDnsName" \
    --output text | xargs
}

get_directory_fields_joined() {
  # Returns a *single* tab-separated line:
  #   <DirectoryId>\t<Stage>\t<dns1, dns2, ...>
  aws ds describe-directories \
    --query "DirectoryDescriptions[?Name=='${DIRECTORY_NAME}'] | [0].[DirectoryId,Stage,join(', ',DnsIpAddrs)]" \
    --output text
}

print_directory_info() {
  local fields dir_id stage dns

  fields="$(get_directory_fields_joined || true)"

  if [ -z "${fields}" ] || [ "${fields}" = "None" ]; then
    echo "WARN: Directory '${DIRECTORY_NAME}' not found"
    return 0
  fi

  IFS=$'\t' read -r dir_id stage dns <<<"${fields}"

  if [ -z "${dns}" ] || [ "${dns}" = "None" ]; then
    dns="N/A"
  fi

  echo "NOTE: Directory INFO:"
  echo ""
  echo "      Name : ${DIRECTORY_NAME}"
  echo "      ID   : ${dir_id}"
  echo "      Stage: ${stage}"
  echo "      DNS  : ${dns}"
}

windows_dns="$(get_public_dns_by_name_tag "windows-ad-instance")"
linux_dns="$(get_public_dns_by_name_tag "linux-ad-instance")"

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

echo ""