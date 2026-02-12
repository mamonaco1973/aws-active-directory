# ==============================================================================
# File: directory.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Deploys an AWS Managed Microsoft Active Directory instance.
#   - Configures VPC-level DNS settings required for domain operation.
#
# Scope:
#   - Creates Microsoft AD directory (Standard edition).
#   - Associates directory with dedicated VPC and subnets.
#   - Configures VPC DHCP options to use AD-provided DNS servers.
#
# Notes:
#   - Directory admin password is sourced from random_password resource.
#   - Two subnets are required for high availability.
#   - DHCP options must reference directory DNS IP addresses.
#   - Domain name and NetBIOS name are variable-driven.
# ==============================================================================


# ==============================================================================
# AWS MANAGED MICROSOFT ACTIVE DIRECTORY
# ==============================================================================

# ------------------------------------------------------------------------------
# Create AWS Managed Microsoft AD directory
# ------------------------------------------------------------------------------

resource "aws_directory_service_directory" "ad_directory" {
  name        = var.ad_domain_name
  password    = random_password.admin_password.result
  edition     = "Standard"
  type        = "MicrosoftAD"
  short_name  = var.netbios
  description = "Managed Microsoft AD for lab and quick-start environments"

  # ---------------------------------------------------------------------------
  # VPC configuration for directory deployment
  # ---------------------------------------------------------------------------

  vpc_settings {
    vpc_id = aws_vpc.ad-vpc.id

    subnet_ids = [
      aws_subnet.ad-subnet-1.id,
      aws_subnet.ad-subnet-2.id
    ]
  }

  depends_on = [ aws_nat_gateway.ad_nat ]
}


# ==============================================================================
# VPC DHCP OPTIONS (AD DNS CONFIGURATION)
# ==============================================================================

# ------------------------------------------------------------------------------
# Create DHCP options set using AD-provided DNS servers
# ------------------------------------------------------------------------------

resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
  domain_name         = var.ad_domain_name
  domain_name_servers = aws_directory_service_directory.ad_directory.dns_ip_addresses
  tags = {
    Name = "${lower(var.netbios)}-dhcp-options"
  }
}


# ------------------------------------------------------------------------------
# Associate DHCP options set with AD VPC
# ------------------------------------------------------------------------------

resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
  vpc_id          = aws_vpc.ad-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options.id
}
