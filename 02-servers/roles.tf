# ================================================================================
# File: roles.tf
# IAM: EC2 Secrets Manager + SSM Access
# ================================================================================
# Purpose:
#   - Creates an EC2 role that can:
#       - Read required AD credential secrets from AWS Secrets Manager.
#       - Register as an SSM managed instance.
#   - Creates an instance profile to attach the role to EC2 instances.
#
# Notes:
#   - Role/profile names include an auto-generated suffix to avoid collisions
#     when deploying multiple stacks.
#   - Naming pattern aligns with other Quick-Start projects.
# ================================================================================


# ================================================================================
# RANDOM SUFFIX: IAM Name Uniqueness
# ================================================================================
# Purpose:
#   - Ensures IAM role/profile names are unique across repeated deployments.
# ================================================================================

resource "random_id" "iam_suffix" {
  byte_length = 3
}

locals {
  iam_id = "ds-${lower(var.netbios)}-${random_id.iam_suffix.hex}"
}


# ================================================================================
# RESOURCE: aws_iam_role.ec2_secrets_role
# ================================================================================
# Purpose:
#   - Trust role assumed by EC2 instances.
# ================================================================================

resource "aws_iam_role" "ec2_secrets_role" {
  name = "ec2-secrets-role-${local.iam_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


# ================================================================================
# RESOURCE: aws_iam_policy.secrets_policy
# ================================================================================
# Purpose:
#   - Grants read access to required AD credential secrets.
# ================================================================================

resource "aws_iam_policy" "secrets_policy" {
  name        = "secrets-read-${local.iam_id}"
  description = "Allow EC2 to read required AD credential secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        data.aws_secretsmanager_secret.admin_secret.arn,
        data.aws_secretsmanager_secret.jsmith_secret.arn,
        data.aws_secretsmanager_secret.edavis_secret.arn,
        data.aws_secretsmanager_secret.rpatel_secret.arn,
        data.aws_secretsmanager_secret.akumar_secret.arn
      ]
    }]
  })
}


# ================================================================================
# ATTACHMENT: AmazonSSMManagedInstanceCore
# ================================================================================
# Purpose:
#   - Enables SSM agent registration and remote management.
# ================================================================================

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ================================================================================
# ATTACHMENT: Secrets Manager Read Policy
# ================================================================================
# Purpose:
#   - Attaches the custom Secrets Manager policy to the EC2 role.
# ================================================================================

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}


# ================================================================================
# RESOURCE: aws_iam_instance_profile.ec2_secrets_profile
# ================================================================================
# Purpose:
#   - Instance profile used to attach the IAM role to EC2 instances.
# ================================================================================

resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "ec2-secrets-profile-${local.iam_id}"
  role = aws_iam_role.ec2_secrets_role.name
}
