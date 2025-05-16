
#!/bin/bash

# Phase 1 of Destroy - delete EC2 instances

export AWS_DEFAULT_REGION=us-east-2  # Required so AWS CLI/Terraform know where to operate

cd 02-servers

terraform init
terraform destroy -auto-approve

cd ..

# Phase 2 of Destroy - delete AD instance

# Force secret deletion

aws secretsmanager delete-secret --secret-id "akumar_ad_credentials" --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id "jsmith_ad_credentials" --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id "edavis_ad_credentials" --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id "rpatel_ad_credentials" --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id "admin_ad_credentials" --force-delete-without-recovery

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..


