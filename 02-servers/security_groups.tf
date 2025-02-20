# Security Group for RDP (Port 3389)
resource "aws_security_group" "ad_rdp_sg" {
  name        = "ad-rdp-security-group"
  description = "Allow RDP access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "Allow RDP from anywhere"
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

# Security Group for SSH (Port 22)
resource "aws_security_group" "ad_ssh_sg" {
  name        = "ad-ssh-security-group"
  description = "Allow SSH access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "Allow SSH from anywhere"
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

# Security Group for SSH (Port 22)
resource "aws_security_group" "ad_ssm_sg" {
  name        = "ad-ssm-security-group"
  description = "Allow SSM access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "Allow SSM from anywhere"
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
