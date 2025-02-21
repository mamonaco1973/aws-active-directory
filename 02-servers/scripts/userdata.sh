#!/bin/bash

# Update the OS to the latest and install required packages

apt-get update -y
export DEBIAN_FRONTEND=noninteractive
apt-get install less unzip realmd sssd-ad sssd-tools libnss-sss libpam-sss adcli samba-common-bin samba-libs oddjob oddjob-mkhomedir packagekit krb5-user nano vim -y

# Install AWS CLI

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -f -r awscliv2.zip

# Do the active directory join

secretValue=$(aws secretsmanager get-secret-value --secret-id ${admin_secret} --query SecretString --output text)
admin_password=$(echo $secretValue | jq -r '.password')
admin_username=$(echo $secretValue | jq -r '.username' | sed 's/.*\\//')
echo -e "$admin_password" | sudo /usr/sbin/realm join -U "$admin_username" ${domain_fqdn} --computer-ou="${computers_ou}" --verbose  >> /tmp/join.log 2>> /tmp/join.log

# Allow password authentication of AD users

sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# SSSD Configuration Chanages

sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sudo sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False/g' /etc/sssd/sssd.conf
sudo sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' /etc/sssd/sssd.conf

sudo systemctl restart sssd
sudo systemctl restart ssh

# Set AD linux admins

sudo echo "%linux-admins" ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/10-linux-admins

# Clean up permissions - instance no longer needs access to secrets

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
association_id=$(aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instance_id" --query "IamInstanceProfileAssociations[0].AssociationId" --output text)
profileName="EC2SSMProfile"
aws ec2 replace-iam-instance-profile-association --iam-instance-profile Name=$profileName --association-id $association_id