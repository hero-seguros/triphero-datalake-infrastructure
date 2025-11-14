# General Configuration
project_name = "hero-trip"
environment  = "prod"
vpc_name     = "hero-trip-prod"

# VPC Peering
vpc_us_east_2_id = "vpc-0f41b5d828db40753"  # hero-trip-prod (10.20.0.0/16)
vpc_sa_east_1_id = "vpc-41df3927"            # TripHero-VPC (172.31.0.0/16)

# MSK Configuration
kafka_version               = "3.8.x"
msk_instance_type          = "kafka.t3.small"
msk_number_of_broker_nodes = 2
msk_ebs_volume_size        = 100

# Additional Tags
additional_tags = {
  CostCenter = "BI"
  Critical   = "true"
}
