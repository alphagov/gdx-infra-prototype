resource "aws_security_group" "kafka_security_group" {
  name           = "gdx-kafka-${var.stack_identifier}-security-group"
  vpc_id         = aws_vpc.gdx_prototype.id
}

resource "aws_security_group_rule" "kafka_allow_private_ingress" {
  security_group_id        = aws_security_group.kafka_security_group.id
  source_security_group_id = aws_security_group.jump_security_group.id
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  type                     = "ingress"
}

resource "aws_security_group_rule" "bootstrap_allow_private_ingress" {
  security_group_id        = aws_security_group.kafka_security_group.id
  source_security_group_id = aws_security_group.jump_security_group.id
  from_port                = 9094
  to_port                  = 9094
  protocol                 = "tcp"
  type                     = "ingress"
}

resource "aws_security_group_rule" "zookeeper_allow_ingress" {
  security_group_id        = aws_security_group.kafka_security_group.id
  source_security_group_id = aws_security_group.jump_security_group.id
  from_port                = 2181
  to_port                  = 2182
  protocol                 = "tcp"
  type                     = "ingress"
}

resource "aws_cloudwatch_log_group" "gdx_msk" {
  name = "gdx-msk-logs"
}

resource "aws_msk_cluster" "kafka_cluster" {
  cluster_name           = "${var.stack_identifier}-gdx-prototype"
  kafka_version          = "2.8.1"
  number_of_broker_nodes = 3

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled = true
        log_group = aws_cloudwatch_log_group.gdx_msk.name
      }
    }
  }
  broker_node_group_info {
    instance_type    = "kafka.t3.small"
    ebs_volume_size  = 50
    client_subnets   = aws_subnet.private[*].id
    security_groups  = [aws_security_group.kafka_security_group.id]
  }
}
