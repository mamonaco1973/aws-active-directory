# ==============================================================================
# File: networking.tf
# ------------------------------------------------------------------------------
# Purpose:
#   - Builds a lab VPC baseline for AWS Managed Microsoft Active Directory.
#
# Scope:
#   - One VPC with:
#       - Two public "vm" subnets for utility/bastion workloads.
#       - Two private "ad" subnets for AWS Directory Service placement.
#   - Internet egress:
#       - Public subnets route to an Internet Gateway (IGW).
#       - Private subnets route to a NAT Gateway for outbound-only access.
#
# Notes:
#   - AWS Managed Microsoft AD requires two subnets in different AZs.
#   - NAT Gateway requires an Elastic IP and must be placed in a public subnet.
#   - CIDRs and AZs are example values. Align these to your IP plan and
#     region/AZ strategy.
#   - This configuration is intentionally explicit (non-dynamic) for clarity in
#     instructional and demo environments.
# ==============================================================================


# ==============================================================================
# VPC
# ==============================================================================

resource "aws_vpc" "ad-vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.vpc_name }
}


# ==============================================================================
# Internet Gateway
# - Provides internet egress for public subnets via default route (0.0.0.0/0).
# ==============================================================================

resource "aws_internet_gateway" "ad-igw" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = { Name = "ad-igw" }
}


# ==============================================================================
# Subnets
# ------------------------------------------------------------------------------
# Public Subnets:
#   - vm-subnet-1: Utility/bastion workloads with public IPv4.
#   - vm-subnet-2: Additional utility capacity / HA option.
#
# Private Subnets:
#   - ad-subnet-1: AWS Directory Service placement subnet (AZ1).
#   - ad-subnet-2: AWS Directory Service placement subnet (AZ2).
# ==============================================================================

resource "aws_subnet" "vm-subnet-1" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.64/26"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = { Name = "vm-subnet-1" }
}

resource "aws_subnet" "vm-subnet-2" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.128/26"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"

  tags = { Name = "vm-subnet-2" }
}

resource "aws_subnet" "ad-subnet-1" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-2a"

  tags = { Name = "ad-subnet-1" }
}

resource "aws_subnet" "ad-subnet-2" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.192/26"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-2b"

  tags = { Name = "ad-subnet-2" }
}


# ==============================================================================
# NAT Egress
# ------------------------------------------------------------------------------
# Purpose:
#   - Provides outbound internet access for instances in private subnets.
#
# Notes:
#   - The NAT Gateway must be deployed into a public subnet.
#   - The Elastic IP provides a stable public egress address.
# ==============================================================================

resource "aws_eip" "nat_eip" {
  tags = { Name = "nat-eip" }
}

resource "aws_nat_gateway" "ad_nat" {
  subnet_id     = aws_subnet.vm-subnet-1.id
  allocation_id = aws_eip.nat_eip.id

  tags = { Name = "ad-nat" }
}


# ==============================================================================
# Route Tables
# ------------------------------------------------------------------------------
# Public:
#   - Default route to IGW for public subnet internet access.
#
# Private:
#   - Default route to NAT for private subnet outbound-only internet access.
# ==============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = { Name = "public-route-table" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ad-igw.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = { Name = "private-route-table" }
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ad_nat.id
}


# ==============================================================================
# Route Table Associations
# ==============================================================================

resource "aws_route_table_association" "rt_assoc_vm_public_1" {
  subnet_id      = aws_subnet.vm-subnet-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "rt_assoc_vm_public_2" {
  subnet_id      = aws_subnet.vm-subnet-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "rt_assoc_ad_private_1" {
  subnet_id      = aws_subnet.ad-subnet-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "rt_assoc_ad_private_2" {
  subnet_id      = aws_subnet.ad-subnet-2.id
  route_table_id = aws_route_table.private.id
}
