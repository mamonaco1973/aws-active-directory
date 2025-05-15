# VPC Definition
resource "aws_vpc" "ad-vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ad-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ad-igw" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = {
    Name = "ad-igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "ad-nat-eip"
  }
}

# NAT Gateway in public subnet 1
resource "aws_nat_gateway" "ad-nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.ad-subnet-1.id

  tags = {
    Name = "ad-nat-gateway"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ad-igw.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ad-nat-gw.id
}

# Public Subnet 1
resource "aws_subnet" "ad-subnet-1" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = false
  availability_zone_id    = "use1-az1"

  tags = {
    Name = "ad-subnet-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "ad-subnet-2" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.64/26"
  map_public_ip_on_launch = false
  availability_zone_id    = "use1-az3"


  tags = {
    Name = "ad-subnet-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "ad-private-subnet-1" {
  vpc_id               = aws_vpc.ad-vpc.id
  cidr_block           = "10.0.0.128/26"
  availability_zone_id = "use1-az6"

  tags = {
    Name = "ad-private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "ad-private-subnet-2" {
  vpc_id               = aws_vpc.ad-vpc.id
  cidr_block           = "10.0.0.192/26"
  availability_zone_id = "use1-az4"

  tags = {
    Name = "ad-private-subnet-2"
  }
}

# Route Table Associations - Public Subnets
resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.ad-subnet-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.ad-subnet-2.id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private Subnets
resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.ad-private-subnet-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.ad-private-subnet-2.id
  route_table_id = aws_route_table.private.id
}
