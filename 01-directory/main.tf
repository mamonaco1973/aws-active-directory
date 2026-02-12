# ==============================================================================
# File: main.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Configures the AWS provider for this Terraform deployment.
#
# Scope:
#   - Defines the AWS region used for all resources in this module.
#
# Notes:
#   - Region is explicitly set for instructional clarity.
#   - In production environments, region should typically be
#     variable-driven.
#   - All resources inherit this provider configuration.
# ==============================================================================


# ==============================================================================
# AWS PROVIDER CONFIGURATION
# ==============================================================================

provider "aws" {
  region = "us-east-2"
}
