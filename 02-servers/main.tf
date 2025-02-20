# Define the AWS provider and set the region to us-east-2 (Ohio)
# Modify this if your deployment requires a different AWS region
provider "aws" {
  region = "us-east-2"
}

# Fetch AWS Secrets Manager secrets for different Active Directory users
# These secrets store AD credentials for authentication purposes

data "aws_secretsmanager_secret" "rpatel_secret" {
  name = "rpatel_ad_credentials" # Secret name in AWS Secrets Manager
}

data "aws_secretsmanager_secret" "edavis_secret" {
  name = "edavis_ad_credentials" # Secret name in AWS Secrets Manager
}

data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials" # Secret name for the admin user in AWS Secrets Manager
}

data "aws_secretsmanager_secret" "jsmith_secret" {
  name = "jsmith_ad_credentials" # Secret name in AWS Secrets Manager
}

data "aws_secretsmanager_secret" "akumar_secret" {
  name = "akumar_ad_credentials" # Secret name in AWS Secrets Manager
}

# Retrieve information about a specific AWS subnet using a tag-based filter
# This subnet will be used for AD services deployment

data "aws_subnet" "ad_subnet_1" {
  filter {
    name   = "tag:Name" # Match based on the 'Name' tag
    values = ["ad-subnet-1"] # Look for a subnet tagged as "ad-subnet-1"
  }
}

# Retrieve information about another AWS subnet for redundancy or HA

data "aws_subnet" "ad_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["ad-subnet-2"] # Look for a subnet tagged as "ad-subnet-2"
  }
}

# Retrieve details of the AWS VPC where Active Directory components will be deployed
# Uses a tag-based filter to locate the correct VPC

data "aws_vpc" "ad_vpc" {
  filter {
    name   = "tag:Name"
    values = ["ad-vpc"] # Look for a VPC tagged as "ad-vpc"
  }
}

# Fetch the most recent Ubuntu AMI provided by Canonical
# This ensures that the latest security patches and features are included

data "aws_ami" "ubuntu_ami" {
  most_recent = true                         # Get the latest available AMI
  owners      = ["099720109477"]             # Canonical's AWS Account ID for official Ubuntu images

  filter {
    name   = "name"                          # Filter AMIs by name pattern
    values = ["*ubuntu-noble-24.04-amd64-*"] # Match Ubuntu 24.04 LTS AMI for x86_64 architecture
  }
}

# Fetch the most recent Windows Server 2022 AMI provided by AWS
# This ensures we deploy the latest Windows Server OS image

data "aws_ami" "windows_ami" {
  most_recent = true                     # Fetch the latest Windows Server AMI
  owners      = ["amazon"]               # AWS official account for Windows AMIs

  filter {
    name   = "name"                                      # Filter AMIs by name pattern
    values = ["Windows_Server-2022-English-Full-Base-*"] # Match Windows Server 2022 AMI
  }
}

# Define an EC2 key pair to allow SSH access to instances
# The public key is read from an existing file

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key-pair"           # Name of the key pair in AWS
  public_key = file("./key.pem.pub")    # Read the public key from a local file
}
