# EC2 INSTANCE CONFIGURATION
# This resource block defines an AWS EC2 instance named "linux_ad_instance".

resource "aws_instance" "linux_ad_instance" {
  
  # AMAZON MACHINE IMAGE (AMI)
  # Reference the Ubuntu AMI ID fetched dynamically via the data source.
  
  ami = data.aws_ami.ubuntu_ami.id

  # INSTANCE TYPE
  # Defines the compute power of the EC2 instance. 
  # "t2.micro" is selected as a cost-effective option with minimal resources.

  instance_type = "t2.micro"

  # NETWORK CONFIGURATION - SUBNET
  # Specifies the AWS subnet where the instance will be deployed.
  # The subnet is dynamically retrieved from a data source (ad_subnet_1).
  
  subnet_id = data.aws_subnet.ad_subnet_1.id

  # SECURITY GROUPS
  # Applies two security groups:
  # 1. `ad_ssh_sg` - Allows SSH access.
  # 2. `ad_ssm_sg` - Allows AWS Systems Manager access for remote management.

  vpc_security_group_ids = [
    aws_security_group.ad_ssh_sg.id,
    aws_security_group.ad_ssm_sg.id
  ]

  # PUBLIC IP ASSIGNMENT
  # Ensures the instance gets a public IP upon launch for external access.
  
  associate_public_ip_address = true

  # SSH KEY PAIR
  # Assigns an SSH key pair for secure access.
  # The key pair is expected to be created elsewhere in the Terraform configuration.
  
  # key_name = aws_key_pair.ec2_key_pair.key_name

  # IAM INSTANCE PROFILE
  # Assigns an IAM role with the necessary permissions for accessing AWS resources securely.
  # This is often used for granting access to S3, Secrets Manager, or other AWS services.
  
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # USER DATA SCRIPT
  # Executes a startup script (`userdata.sh`) when the instance boots up.
  # This script is dynamically templated with values required for setup:
  # - `admin_secret`: The administrator credentials secret
  # - `domain_fqdn`: The fully qualified domain name (FQDN) for the environment.
  # - `computers_ou`: The Organizational Unit where computers are registered in Active Directory.

  user_data = templatefile("./scripts/userdata.sh", { 
    admin_secret = "admin_ad_credentials"                       # The administrator credentials secret
    domain_fqdn  = "mikecloud.com"                              # The domain FQDN for Active Directory integration.
    computers_ou = "OU=Computers,OU=MCLOUD,DC=mcloud,DC=mikecloud,DC=com" # The AD OU where computers will be placed.
  })

  # INSTANCE TAGS
  # Metadata tag used to identify and organize resources in AWS.

  tags = {
    Name = "linux-ad-instance"  # The EC2 instance name in AWS.
  }
}
