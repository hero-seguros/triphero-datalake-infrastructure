# MSK Outputs
output "msk_cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = aws_msk_cluster.main.arn
}

output "msk_cluster_name" {
  description = "Name of the MSK cluster"
  value       = aws_msk_cluster.main.cluster_name
}

output "msk_bootstrap_brokers_sasl_iam" {
  description = "MSK bootstrap brokers for SASL/IAM authentication"
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
  sensitive   = true
}

output "msk_bootstrap_brokers_tls" {
  description = "MSK bootstrap brokers for TLS authentication"
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
  sensitive   = true
}

output "msk_zookeeper_connect_string" {
  description = "Zookeeper connection string"
  value       = aws_msk_cluster.main.zookeeper_connect_string
  sensitive   = true
}

output "msk_security_group_id" {
  description = "Security group ID for MSK cluster"
  value       = aws_security_group.msk.id
}

# IAM Outputs
output "debezium_role_arn" {
  description = "ARN of the IAM role for Debezium"
  value       = aws_iam_role.debezium.arn
}

output "debezium_role_name" {
  description = "Name of the IAM role for Debezium"
  value       = aws_iam_role.debezium.name
}

# Connection Info
output "kafka_connection_info" {
  description = "Information to connect to Kafka cluster"
  value = {
    cluster_name              = aws_msk_cluster.main.cluster_name
    kafka_version             = aws_msk_cluster.main.kafka_version
    number_of_broker_nodes    = aws_msk_cluster.main.number_of_broker_nodes
    authentication_method     = "SASL/IAM"
    encryption_in_transit     = "TLS"
    bootstrap_brokers_command = "aws kafka get-bootstrap-brokers --cluster-arn ${aws_msk_cluster.main.arn} --region ${var.aws_region}"
  }
}

# VPC Peering Outputs
output "vpc_peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.cross_region.id
}

output "vpc_peering_status" {
  description = "VPC Peering Connection Status"
  value       = aws_vpc_peering_connection.cross_region.accept_status
}

output "vpc_peering_info" {
  description = "VPC Peering Connection Information"
  value = {
    peering_id      = aws_vpc_peering_connection.cross_region.id
    requester_vpc   = "${var.vpc_us_east_2_id} (us-east-2)"
    accepter_vpc    = "${var.vpc_sa_east_1_id} (sa-east-1)"
    requester_cidr  = data.aws_vpc.us_east_2.cidr_block
    accepter_cidr   = data.aws_vpc.sa_east_1.cidr_block
    status          = aws_vpc_peering_connection.cross_region.accept_status
  }
}
