# VPC Peering Connection (sa-east-1 ↔ us-east-2)
# Connects RDS instances (sa-east-1) to MSK/Debezium (us-east-2)

# Requester VPC (us-east-2 - MSK/EKS)
data "aws_vpc" "us_east_2" {
  provider = aws.us_east_2
  id       = var.vpc_us_east_2_id
}

# Accepter VPC (sa-east-1 - RDS)
data "aws_vpc" "sa_east_1" {
  provider = aws.sa_east_1
  id       = var.vpc_sa_east_1_id
}

# Create VPC Peering Connection from us-east-2 to sa-east-1
resource "aws_vpc_peering_connection" "cross_region" {
  provider    = aws.us_east_2
  vpc_id      = data.aws_vpc.us_east_2.id
  peer_vpc_id = data.aws_vpc.sa_east_1.id
  peer_region = "sa-east-1"

  tags = {
    Name        = "${var.project_name}-${var.environment}-peering"
    Environment = var.environment
    Side        = "Requester"
  }
}

# Accept VPC Peering Connection in sa-east-1
resource "aws_vpc_peering_connection_accepter" "sa_east_1" {
  provider                  = aws.sa_east_1
  vpc_peering_connection_id = aws_vpc_peering_connection.cross_region.id
  auto_accept               = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-peering"
    Environment = var.environment
    Side        = "Accepter"
  }
}

# Get route tables from us-east-2 VPC
data "aws_route_tables" "us_east_2" {
  provider = aws.us_east_2
  vpc_id   = data.aws_vpc.us_east_2.id
}

# Get route tables from sa-east-1 VPC
data "aws_route_tables" "sa_east_1" {
  provider = aws.sa_east_1
  vpc_id   = data.aws_vpc.sa_east_1.id
}

# Add routes in us-east-2 to reach sa-east-1 CIDR
resource "aws_route" "us_east_2_to_sa_east_1" {
  provider                  = aws.us_east_2
  for_each                  = toset(data.aws_route_tables.us_east_2.ids)
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.sa_east_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cross_region.id

  depends_on = [aws_vpc_peering_connection_accepter.sa_east_1]
}

# Add routes in sa-east-1 to reach us-east-2 CIDR
resource "aws_route" "sa_east_1_to_us_east_2" {
  provider                  = aws.sa_east_1
  for_each                  = toset(data.aws_route_tables.sa_east_1.ids)
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.us_east_2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cross_region.id

  depends_on = [aws_vpc_peering_connection_accepter.sa_east_1]
}
