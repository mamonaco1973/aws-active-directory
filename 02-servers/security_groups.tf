# ==============================================================================
# File: security_groups.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Defines security groups for EC2 instances deployed in this stack.
#
# Scope:
#   - RDP access for Windows instances.
#   - SSH access for Linux instances.
#   - HTTPS access for Systems Manager (SSM) communication.
#
# Notes:
#   - Ingress rules allow access from 0.0.0.0/0 for quick-start simplicity.
#   - This is NOT production-safe.
#   - Restrict CIDR ranges to trusted IP space before real-world use.
#   - Egress is fully open to allow outbound internet access.
# ==============================================================================


# ==============================================================================
# SECURITY GROUP: RDP (PORT 3389)
# ==============================================================================
# Purpose:
#   - Allows Remote Desktop access to Windows instances.
# ==============================================================================

resource "aws_security_group" "ad_rdp_sg" {
  name        = "ad-rdp-security-group"
  description = "Allow RDP access (quick-start configuration)"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "RDP access from anywhere (not production safe)"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ==============================================================================
# SECURITY GROUP: SSH (PORT 22)
# ==============================================================================
# Purpose:
#   - Allows SSH access to Linux instances.
# ==============================================================================

resource "aws_security_group" "ad_ssh_sg" {
  name        = "ad-ssh-security-group"
  description = "Allow SSH access (quick-start configuration)"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "SSH access from anywhere (not production safe)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ==============================================================================
# SECURITY GROUP: SSM (PORT 443)
# ==============================================================================
# Purpose:
#   - Allows HTTPS communication required for SSM agent connectivity.
# ==============================================================================

resource "aws_security_group" "ad_ssm_sg" {
  name        = "ad-ssm-security-group"
  description = "Allow SSM HTTPS access (quick-start configuration)"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "HTTPS from anywhere (not production safe)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
