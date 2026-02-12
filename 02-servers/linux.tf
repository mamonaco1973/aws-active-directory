# ==============================================================================
# File: linux.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Deploys a Linux EC2 instance joined to the Active Directory domain.
#
# Scope:
#   - Launches Ubuntu instance in designated AD subnet.
#   - Applies SSH and SSM security groups.
#   - Assigns IAM instance profile for Secrets Manager access.
#   - Executes user-data script for domain join configuration.
#
# Notes:
#   - AMI is resolved dynamically via data source.
#   - Instance type is intentionally small for lab environments.
#   - Public IP assignment simplifies quick-start access.
#   - Domain-specific values are explicitly defined for clarity.
# ==============================================================================


# ==============================================================================
# LINUX EC2 INSTANCE (AD MEMBER)
# ==============================================================================

resource "aws_instance" "linux_ad_instance" {

  # ---------------------------------------------------------------------------
  # Amazon Machine Image (AMI)
  # ---------------------------------------------------------------------------

  ami = data.aws_ami.ubuntu_ami.id

  # ---------------------------------------------------------------------------
  # Instance Size
  # ---------------------------------------------------------------------------

  instance_type = "t2.micro"

  # ---------------------------------------------------------------------------
  # Network Placement
  # ---------------------------------------------------------------------------

  subnet_id = data.aws_subnet.vm_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.ad_ssh_sg.id,
    aws_security_group.ad_ssm_sg.id
  ]

  associate_public_ip_address = true

  # ---------------------------------------------------------------------------
  # IAM Instance Profile
  # ---------------------------------------------------------------------------

  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # ---------------------------------------------------------------------------
  # User Data (Domain Join Configuration)
  # ---------------------------------------------------------------------------

  user_data = templatefile("./scripts/userdata.sh", {
    admin_secret = "admin_ad_credentials_ds"
    domain_fqdn  = var.ad_domain_name
    computers_ou = var.computers_ou
  })

  # ---------------------------------------------------------------------------
  # Tags
  # ---------------------------------------------------------------------------

  tags = {
    Name = "linux-ad-instance"
  }
}
