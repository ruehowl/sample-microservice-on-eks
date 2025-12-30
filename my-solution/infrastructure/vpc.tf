# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet 1 (AZ 1)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
    Type = "Public"
  }
}

# Public Subnet 2 (AZ 2)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
    Type = "Public"
  }
}

# Private Subnet 1 (AZ 1)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-subnet-1"
    Type = "Private"
  }
}

# Private Subnet 2 (AZ 2)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-subnet-2"
    Type = "Private"
  }
}

# Elastic IP for NAT Gateway 1
resource "aws_eip" "nat_1" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip-1"
  }
}

# NAT Gateway 1 (in public subnet 1)
resource "aws_nat_gateway" "main_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-gw-1"
  }
}

# Elastic IP for NAT Gateway 2
resource "aws_eip" "nat_2" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip-2"
  }
}

# NAT Gateway 2 (in public subnet 2)
resource "aws_nat_gateway" "main_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-gw-2"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Public Route Table Association 1
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table 1
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_1.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-1"
  }
}

# Private Route Table Association 1
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# Private Route Table 2
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_2.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-2"
  }
}

# Private Route Table Association 2
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}
