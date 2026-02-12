# ==============================================================================
# File: main.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Configures AWS provider and shared data sources for server deployment.
#
# Scope:
#   - Defines AWS region.
#   - Retrieves Active Directory credentials from Secrets Manager.
#   - Locates target VPC and AD subnets.
#   - Resolves current Ubuntu and Windows AMIs.
#
# Notes:
#   - Region is explicitly defined for quick-start clarity.
#   - Subnet lookups are constrained to the target VPC to prevent ambiguity.
#   - Ubuntu AMI ID is sourced from Canonical-maintained SSM parameter.
#   - AMI resolution is deterministic and owner-restricted.
# ==============================================================================


# ==============================================================================
# AWS PROVIDER
# ==============================================================================

provider "aws" {
  region = "us-east-2"
}


# ==============================================================================
# SECRETS MANAGER LOOKUPS (ACTIVE DIRECTORY CREDENTIALS)
# ==============================================================================

data "aws_secretsmanager_secret" "rpatel_secret" {
  name = "rpatel_ad_credentials_ds"
}

data "aws_secretsmanager_secret" "edavis_secret" {
  name = "edavis_ad_credentials_ds"
}

data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials_ds"
}

data "aws_secretsmanager_secret" "jsmith_secret" {
  name = "jsmith_ad_credentials_ds"
}

data "aws_secretsmanager_secret" "akumar_secret" {
  name = "akumar_ad_credentials_ds"
}


# ==============================================================================
# VPC LOOKUP
# ==============================================================================

data "aws_vpc" "ad_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}


# ==============================================================================
# SUBNET LOOKUPS (SCOPED TO TARGET VPC)
# ==============================================================================

data "aws_subnet" "vm_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["vm-subnet-1"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ad_vpc.id]
  }
}

data "aws_subnet" "vm_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["vm-subnet-2"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ad_vpc.id]
  }
}


# ==============================================================================
# AMI RESOLUTION
# ==============================================================================

# ==============================================================================
# Ubuntu 24.04 LTS (Canonical via SSM)
# ------------------------------------------------------------------------------
# Purpose:
#   - Retrieves the latest stable Ubuntu 24.04 LTS AMI ID from AWS SSM.
#
# Notes:
#   - Path is maintained by Canonical.
#   - Always resolves to current amd64 HVM gp3-backed image.
# ==============================================================================

data "aws_ssm_parameter" "ubuntu_24_04" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# ==============================================================================
# Canonical Ubuntu AMI Lookup
# ------------------------------------------------------------------------------
# Purpose:
#   - Resolves the full AMI object using the ID returned from SSM.
#
# Scope:
#   - Restricts owner to Canonical.
#   - Filters explicitly by image-id for deterministic resolution.
#
# Notes:
#   - most_recent retained defensively if duplicate IDs exist.
# ==============================================================================

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.ubuntu_24_04.value]
  }
}


# ==============================================================================
# Windows Server 2022 (AWS Official)
# ------------------------------------------------------------------------------

data "aws_ami" "windows_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}
