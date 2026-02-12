#!/bin/bash
set -euo pipefail

LOG=/root/userdata.log
mkdir -p /root
touch "$LOG"
chmod 600 "$LOG"
exec > >(tee -a "$LOG" | logger -t user-data -s 2>/dev/console) 2>&1
trap 'echo "ERROR at line $LINENO"; exit 1' ERR

echo "user-data start: $(date -Is)"

# Inputs (Terraform)
ADMIN_SECRET="${admin_secret}"
DOMAIN_FQDN="${domain_fqdn}"

# SSM
snap install amazon-ssm-agent --classic || true
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# Packages
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  less unzip curl jq \
  realmd sssd-ad sssd-tools libnss-sss libpam-sss \
  adcli samba-common-bin samba-libs \
  oddjob oddjob-mkhomedir packagekit krb5-user \
  nano vim

# AWS CLI v2
cd /tmp
curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install --update
rm -rf awscliv2.zip aws

# Join AD
SECRET_JSON="$(aws secretsmanager get-secret-value \
  --secret-id "$ADMIN_SECRET" \
  --query SecretString \
  --output text)"

ADMIN_PASSWORD="$(echo "$SECRET_JSON" | jq -r '.password')"
ADMIN_USERNAME="$(echo "$SECRET_JSON" | jq -r '.username' | sed 's/.*\\//')"

if ! realm list | grep -qi "$DOMAIN_FQDN"; then
  echo "$ADMIN_PASSWORD" | realm join -U "$ADMIN_USERNAME" "$DOMAIN_FQDN" \
    --verbose >> /root/join.log 2>&1
fi

# SSH password auth
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' \
    /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
else
  sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/g' \
    /etc/ssh/sshd_config || true
fi

# SSSD tweaks
if [ -f /etc/sssd/sssd.conf ]; then
  sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf || true
  sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False/g' /etc/sssd/sssd.conf || true
  sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|g' /etc/sssd/sssd.conf || true
  chmod 600 /etc/sssd/sssd.conf || true
fi

touch /etc/skel/.Xauthority
chmod 600 /etc/skel/.Xauthority

pam-auth-update --enable mkhomedir || true
systemctl restart sssd || true
systemctl restart ssh || systemctl restart sshd || true

# Sudo (idempotent)
SUDO_FILE=/etc/sudoers.d/10-linux-admins
if [ ! -f "$SUDO_FILE" ]; then
  echo "%linux-admins ALL=(ALL) NOPASSWD:ALL" > "$SUDO_FILE"
  chmod 440 "$SUDO_FILE"
fi

realm list || true
echo "user-data complete: $(date -Is)"
