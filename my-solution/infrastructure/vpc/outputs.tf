# VPC Module Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Public Subnet Outputs
output "public_subnet_1_id" {
  description = "ID of the public subnet 1 (AZ1)"
  value       = aws_subnet.public_1.id
}

output "public_subnet_1_cidr" {
  description = "CIDR block of the public subnet 1"
  value       = aws_subnet.public_1.cidr_block
}

output "public_subnet_2_id" {
  description = "ID of the public subnet 2 (AZ2)"
  value       = aws_subnet.public_2.id
}

output "public_subnet_2_cidr" {
  description = "CIDR block of the public subnet 2"
  value       = aws_subnet.public_2.cidr_block
}

# Private Subnet Outputs
output "private_subnet_1_id" {
  description = "ID of the private subnet 1 (AZ1)"
  value       = aws_subnet.private_1.id
}

output "private_subnet_1_cidr" {
  description = "CIDR block of the private subnet 1"
  value       = aws_subnet.private_1.cidr_block
}

output "private_subnet_2_id" {
  description = "ID of the private subnet 2 (AZ2)"
  value       = aws_subnet.private_2.id
}

output "private_subnet_2_cidr" {
  description = "CIDR block of the private subnet 2"
  value       = aws_subnet.private_2.cidr_block
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# NAT Gateway Outputs
output "nat_gateway_1_id" {
  description = "ID of the NAT Gateway 1 (AZ1)"
  value       = aws_nat_gateway.main_1.id
}

output "nat_gateway_1_eip" {
  description = "Elastic IP address of the NAT Gateway 1"
  value       = aws_eip.nat_1.public_ip
}

output "nat_gateway_2_id" {
  description = "ID of the NAT Gateway 2 (AZ2)"
  value       = aws_nat_gateway.main_2.id
}

output "nat_gateway_2_eip" {
  description = "Elastic IP address of the NAT Gateway 2"
  value       = aws_eip.nat_2.public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_1_id" {
  description = "ID of the private route table 1 (AZ1)"
  value       = aws_route_table.private_1.id
}

output "private_route_table_2_id" {
  description = "ID of the private route table 2 (AZ2)"
  value       = aws_route_table.private_2.id
}
