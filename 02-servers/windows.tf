# ==============================================================================
# File: windows.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Deploys a Windows EC2 instance joined to the Active Directory domain.
#
# Scope:
#   - Launches Windows Server instance in designated AD subnet.
#   - Applies RDP and SSM security groups.
#   - Assigns IAM instance profile for Secrets Manager access.
#   - Executes PowerShell user-data script for domain join configuration.
#
# Notes:
#   - AMI is resolved dynamically via data source.
#   - Instance type is sized larger than Linux due to Windows requirements.
#   - Public IP assignment simplifies quick-start access.
#   - Domain-specific values are explicitly defined for clarity.
# ==============================================================================


# ==============================================================================
# WINDOWS EC2 INSTANCE (AD MEMBER)
# ==============================================================================

resource "aws_instance" "windows_ad_instance" {

  # ---------------------------------------------------------------------------
  # Amazon Machine Image (AMI)
  # ---------------------------------------------------------------------------

  ami = data.aws_ami.windows_ami.id

  # ---------------------------------------------------------------------------
  # Instance Size
  # ---------------------------------------------------------------------------

  instance_type = "t2.medium"

  # ---------------------------------------------------------------------------
  # Network Placement
  # ---------------------------------------------------------------------------

  subnet_id = data.aws_subnet.vm_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.ad_rdp_sg.id,
    aws_security_group.ad_ssm_sg.id
  ]

  associate_public_ip_address = true

  # ---------------------------------------------------------------------------
  # IAM Instance Profile
  # ---------------------------------------------------------------------------

  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # ---------------------------------------------------------------------------
  # User Data (PowerShell Domain Join Configuration)
  # ---------------------------------------------------------------------------

  user_data = templatefile("./scripts/userdata.ps1", {
    admin_secret = "admin_ad_credentials_ds"
    domain_fqdn  = var.ad_domain_name
    computers_ou = var.computers_ou
  })

  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------

  tags = {
    Name = "windows-ad-instance"
  }
}
