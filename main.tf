# MSK Security Group
resource "aws_security_group" "msk" {
  name        = "${var.project_name}-${var.environment}-msk"
  description = "Security group for MSK cluster"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-msk"
  }
}

# MSK Security Group Rules - Allow traffic from EKS nodes
resource "aws_security_group_rule" "msk_ingress_eks" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9098
  protocol                 = "tcp"
  source_security_group_id = data.aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.msk.id
  description              = "Allow Kafka traffic from EKS cluster"
}

# MSK Security Group Rules - Allow internal communication between brokers
resource "aws_security_group_rule" "msk_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.msk.id
  description       = "Allow internal MSK broker communication"
}

# MSK Security Group Rules - Egress
resource "aws_security_group_rule" "msk_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.msk.id
  description       = "Allow all outbound traffic"
}

# MSK Cluster Configuration
resource "aws_msk_configuration" "main" {
  name              = "${var.project_name}-${var.environment}-msk-config"
  kafka_versions    = [var.kafka_version]
  server_properties = <<PROPERTIES
auto.create.topics.enable=true
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=false
zookeeper.session.timeout.ms=18000
log.retention.hours=168
log.segment.bytes=1073741824
compression.type=gzip
PROPERTIES
}

# MSK Cluster
resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.project_name}-${var.environment}-msk"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.msk_number_of_broker_nodes
  enhanced_monitoring    = "DEFAULT"

  broker_node_group_info {
    instance_type  = var.msk_instance_type
    client_subnets = data.aws_subnets.private.ids
    storage_info {
      ebs_storage_info {
        volume_size = var.msk_ebs_volume_size
      }
    }
    security_groups = [aws_security_group.msk.id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  # Basic monitoring only (no enhanced monitoring)
  # CloudWatch logs disabled to reduce costs
  # logging_info {
  #   broker_logs {
  #     cloudwatch_logs {
  #       enabled   = false
  #     }
  #   }
  # }

  tags = {
    Name = "${var.project_name}-${var.environment}-msk"
  }
}

