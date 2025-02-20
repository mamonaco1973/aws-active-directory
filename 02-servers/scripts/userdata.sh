#!/bin/bash

# Update the OS to the latest and install required packages

sudo apt update -y
sudo apt install less unzip sssd realmd  -y

# Do the active directory join

admin_password=$(aws secretsmanager get-secret-value --secret-id admin_ad_credentials --query SecretString --output text | jq -r '.password')

# Clean up permissions - instance no longer needs access to secrets

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
association_id=$(aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instance_id" --query "IamInstanceProfileAssociations[0].AssociationId" --output text)
aws ec2 disassociate-iam-instance-profile --association-id $association_id

# Add comment