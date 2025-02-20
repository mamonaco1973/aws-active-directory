#!/bin/bash

# Update the OS package lists and install necessary dependencies for Active Directory integration
# - 'less' and 'unzip' for utility functions
# - 'realmd' for discovering and joining AD domains
# - 'sssd' and related tools for authentication
# - 'adcli' for joining AD domains
# - 'samba-common-bin' and 'samba-libs' for compatibility with Samba services
# - 'oddjob' and 'oddjob-mkhomedir' for automatically creating home directories
# - 'packagekit' for managing software updates
# - 'krb5-user' for Kerberos authentication
# - 'nano' and 'vim' for text editing
sudo apt update -y
sudo apt install less unzip realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin samba-libs oddjob oddjob-mkhomedir packagekit krb5-user nano vim -y

# Retrieve AD administrator credentials from AWS Secrets Manager
# - Fetch the secret value using AWS CLI
# - Extract the 'username' and 'password' fields from the JSON response
# - Strip domain information from the username using 'sed'
secretValue=$(aws secretsmanager get-secret-value --secret-id ${admin_secret} --query SecretString --output text)
admin_password=$(echo $secretValue | jq -r '.password')
admin_username=$(echo $secretValue | jq -r '.username' | sed 's/.*\\//')

# Join the Active Directory domain
# - Authenticate using the extracted admin credentials
# - Use the specified Organizational Unit (OU) for computer objects
# - Log all output and errors to '/tmp/join.log' for debugging purposes
echo -e "$admin_password" | sudo /usr/sbin/realm join -U "$admin_username" ${domain_fqdn} --computer-ou="${computers_ou}" --verbose  >> /tmp/join.log 2>> /tmp/join.log

# Modify SSH configuration to allow password authentication for Active Directory users
# - Update the SSH daemon configuration file
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# Update SSSD (System Security Services Daemon) configuration
# - Disable fully qualified usernames (e.g., 'user@domain' -> 'user')
# - Disable LDAP ID mapping to use consistent UID/GID from AD
# - Adjust fallback home directory format (remove domain suffix from home path)
sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sudo sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False/g' /etc/sssd/sssd.conf
sudo sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' /etc/sssd/sssd.conf

# Restart SSSD and SSH services to apply changes

sudo pam-auth-update --enable mkhomedir
sudo systemctl restart sssd
sudo systemctl restart ssh

# Grant 'linux-admins' AD group full sudo privileges without a password prompt
# - Append a rule to the sudoers configuration file
sudo echo "%linux-admins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/10-linux-admins

# Retrieve the instance ID from AWS EC2 metadata
# - Use IMDSv2 (Instance Metadata Service Version 2) for security
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# Retrieve IAM instance profile association ID for the current EC2 instance
# - Fetch the first associated IAM profile
association_id=$(aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instance_id" --query "IamInstanceProfileAssociations[0].AssociationId" --output text)

# Reassign the instance IAM profile to a less privileged profile
# - Replace the existing IAM instance profile with a new profile ('EC2SSMProfile')
# - This prevents the instance from having unnecessary access to AWS Secrets Manager
profileName="EC2SSMProfile"
aws ec2 replace-iam-instance-profile-association --iam-instance-profile Name=$profileName --association-id $association_id
