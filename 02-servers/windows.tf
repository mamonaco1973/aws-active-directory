# EC2 Instance Configuration
resource "aws_instance" "windows_ad_instance" {
  ami                      = data.aws_ami.windows_ami.id           # Use the selected AMI
  instance_type            = "t2.medium"                           # Instance type
  subnet_id                = data.aws_subnet.ad_subnet_2.id        # Launch in the public subnet
  vpc_security_group_ids   = [aws_security_group.ad_rdp_sg.id]     # Apply the security group
  associate_public_ip_address = true                               # Enable public IP assignment
  
  key_name = aws_key_pair.ec2_key_pair.key_name                    # Use the created key pair 
  iam_instance_profile     = aws_iam_instance_profile.ec2_secrets_profile.name  
                                                                   # Specify the IAM instance profile
  user_data = file("./scripts/userdata.ps1")                       # Bootstrap script to initialize instance

  tags = {
    Name = "windows-ad-instance"                                   # Tag to identify the EC2 instance
  }
}
