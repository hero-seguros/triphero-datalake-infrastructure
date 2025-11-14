variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name (format: biz-app)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC to deploy resources"
  type        = string
}

# VPC Peering Configuration
variable "vpc_us_east_2_id" {
  description = "VPC ID in us-east-2 (MSK/EKS)"
  type        = string
}

variable "vpc_sa_east_1_id" {
  description = "VPC ID in sa-east-1 (RDS)"
  type        = string
}

# MSK Configuration
variable "kafka_version" {
  description = "Kafka version for MSK"
  type        = string
  default     = "3.9.x"
}

variable "msk_instance_type" {
  description = "Instance type for MSK broker nodes"
  type        = string
  default     = "kafka.t3.small"
}

variable "msk_number_of_broker_nodes" {
  description = "Number of broker nodes in MSK cluster (must be multiple of AZs)"
  type        = number
  default     = 2
}

variable "msk_ebs_volume_size" {
  description = "EBS volume size for MSK brokers in GB"
  type        = number
  default     = 100
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
