
provider "aws" {
  region = "us-east-2" # Default region set to US East (Ohio). Modify if your deployment requires another region.
}


data "aws_secretsmanager_secret" "rpatel_secret" {
  name = "rpatel_ad_credentials"
}

data "aws_secretsmanager_secret" "edavis_secret" {
  name = "edavis_ad_credentials"
}

data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials"
}

data "aws_secretsmanager_secret" "jsmith_secret" {
  name = "jsmith_ad_credentials"
}

data "aws_secretsmanager_secret" "akumar_secret" {
  name = "akumar_ad_credentials"
}

data "aws_subnet" "ad_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["ad-subnet-1"]
  }
}

data "aws_subnet" "ad_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["ad-subnet-2"]
  }
}

data "aws_vpc" "ad_vpc" {
  filter {
    name   = "tag:Name"
    values = ["ad-vpc"]
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true                    # Fetch the most recent AMI
  owners      = ["099720109477"]        # Canonical's AWS Account ID

  filter {
    name   = "name"                           # Filter AMIs by name
    values = ["*ubuntu-noble-24.04-amd64-*"]  # Match Ubuntu AMI
  }
}

data "aws_ami" "windows_ami" {
  most_recent = true                    # Fetch the most recent AMI
  owners      = ["amazon"]        

  filter {
    name   = "name"                      
    values = ["Windows_Server-2022-English-Full-Base-*"]  
  }
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key-pair"            # Key pair name
  public_key = file("./key.pem.pub")     # Path to the public key file
}
