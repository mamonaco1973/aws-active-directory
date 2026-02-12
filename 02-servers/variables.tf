# ==============================================================================
# File: variables.tf
# ------------------------------------------------------------------------------
# Purpose:
#   Define configurable inputs for Active Directory deployment.
# ==============================================================================

variable "ad_domain_name" {
  description = "Fully qualified domain name (FQDN) for Microsoft AD"
  type        = string
  default     = "mcloud.mikecloud.com"
}

variable "netbios" {
  description = "NetBIOS short name for the AD domain"
  type        = string
  default     = "MCLOUD"
}

variable "computers_ou" {
  description = "Computers OU for the join"
  type        = string
  default     = "OU=Computers,OU=MCLOUD,DC=mcloud,DC=mikecloud,DC=com"
}

# ------------------------------------------------------------------------------
# VPC Name
# ------------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name tag assigned to the Active Directory VPC"
  type        = string
  default     = "directory-vpc"
}

