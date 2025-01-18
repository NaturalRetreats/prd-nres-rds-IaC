# This code is only for Production environment. This code will create Subnets, Security Groups, Application Load Balancer, RDS Instance, WAF
# and all other required resources in AWS.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }
  }

  backend "s3" {
    bucket         = "prd-nres-rds-tfstate"
    key            = "prd-nres-rds-tfstate-fld/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "prd-tf-state-lock-nres-dyndb"
  }
}

# ---------------Below code is for Listener Subnets----------------
data "aws_vpc" "prd_vpc" {
  id = "vpc-0a7fa0c2492fdae89" # Default vpc for nres
}

resource "aws_subnet" "prd-listener-subnet-az1a" {
  vpc_id                  = data.aws_vpc.prd_vpc.id
  cidr_block              = var.listener_subnet_1a_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "prd-listener-subnet-az1a"
    }
  )
}

resource "aws_subnet" "prd-listener-subnet-az1b" {
  vpc_id                  = data.aws_vpc.prd_vpc.id
  cidr_block              = var.listener_subnet_1b_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "prd-listener-subnet-az1b"
    }
  )
}

resource "aws_subnet" "prd-rds-subnet-az1a" {
  vpc_id                  = data.aws_vpc.prd_vpc.id
  cidr_block              = var.rds_subnet_1a_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "prd-rds-subnet-az1a"
    }
  )
}

resource "aws_subnet" "prd-rds-subnet-az1b" {
  vpc_id                  = data.aws_vpc.prd_vpc.id
  cidr_block              = var.rds_subnet_1b_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "prd-rds-subnet-az1b"
    }
  )
}

# DMS Subnet Group
resource "aws_dms_replication_subnet_group" "prd-dms-subnet-grp" {
  replication_subnet_group_description = "Subnet group for prd dms"
  replication_subnet_group_id          = "prd-dms-subnet-grp"

  subnet_ids = [
    aws_subnet.prd-rds-subnet-az1a.id,
    aws_subnet.prd-rds-subnet-az1b.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "prd-dms-subnet-grp"
    }
  )
}

# Route Table Associations

data "aws_route_table" "prd-route-table" {
  route_table_id = "rtb-07626cb1dcc0653d8" # this is the main route table for the vpc "vpc-0a7fa0c2492fdae89" #nres
}


resource "aws_route_table_association" "prd-listener-subnet-az1a" {
  subnet_id      = aws_subnet.prd-listener-subnet-az1a.id
  route_table_id = data.aws_route_table.prd-route-table.id

}

resource "aws_route_table_association" "prd-listener-subnet-az1b" {
  subnet_id      = aws_subnet.prd-listener-subnet-az1b.id
  route_table_id = data.aws_route_table.prd-route-table.id

}

resource "aws_route_table_association" "prd-rds-subnet-az1a" {
  subnet_id      = aws_subnet.prd-rds-subnet-az1a.id
  route_table_id = data.aws_route_table.prd-route-table.id

}

resource "aws_route_table_association" "prd-rds-subnet-az1b" {
  subnet_id      = aws_subnet.prd-rds-subnet-az1b.id
  route_table_id = data.aws_route_table.prd-route-table.id
}

# Application Load Balancer
resource "aws_lb" "prd-nres-alb" {
  name                       = "prd-nres-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.prd-alb-sg.id]
  subnets                    = [aws_subnet.prd-listener-subnet-az1a.id, aws_subnet.prd-listener-subnet-az1b.id]
  enable_deletion_protection = true

  tags = merge(
    local.common_tags,
    {
      Name = "prd-nres-alb"
    }
  )
}

# Security Groups
resource "aws_security_group" "prd-alb-sg" {
  name        = "prd-alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.prd_vpc.id

  ingress {
    description = "Allow HTTP inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound 7443" # this is for https://proxy.naturalretreats.com:7443
    from_port   = 7443
    to_port     = 7443
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.prd-rds-subnet-az1a.cidr_block,
      aws_subnet.prd-rds-subnet-az1b.cidr_block
    ]
  }

  egress {
    description = "Allow all outbound traffic" # This rule can be removed later
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "prd-alb-sg"
    }
  )
}

resource "aws_security_group" "prd-ec2-sg" {
  name        = "prd-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.prd_vpc.id

  ingress {
    description     = "Allow inbound 8443" # from ALB 443 --> 8443
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.prd-alb-sg.id]
  }

  ingress {
    description     = "Allow inbound 7443" # this is for https://proxy.naturalretreats.com:7443 7443 --> 7443 coming from alb
    from_port       = 7443
    to_port         = 7443
    protocol        = "tcp"
    security_groups = [aws_security_group.prd-alb-sg.id]
  }

  ingress {
    description     = "Allow inbound 22" # unless a public IP is assigned to the ec2 instance, this rule is not required. or you may use a bastion host.
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow Oracle DB access" # to RDS
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.prd-rds-subnet-az1a.cidr_block,
      aws_subnet.prd-rds-subnet-az1b.cidr_block
    ]
  }

  /*egress {
    description = "Allow all outbound traffic" # This egress rule should be removed later.
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }*/

  tags = merge(
    local.common_tags,
    {
      Name = "prd-ec2-sg"
    }
  )
}

resource "aws_security_group" "prd-rds-sg" {
  name        = "prd-rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = data.aws_vpc.prd_vpc.id

  ingress {
    description = "Allow Oracle DB access"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.prd-listener-subnet-az1a.cidr_block,
      aws_subnet.prd-listener-subnet-az1b.cidr_block
    ]
  }

  ingress {
    description = "Allow inbound 1521 from internet" # think of removing this rule later.
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow SMTP traffic"
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic" # this rule should be removed later.
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "prd-rds-sg"
    }
  )
}

# RDS Configuration
resource "aws_db_option_group" "prd-oradb-opt-group" {
  name                     = "prd-oradb-opt-group"
  engine_name              = "oracle-se2"
  major_engine_version     = "19"
  option_group_description = "Option group for Oracle SE2 19c with APEX and S3 integration"

  option {
    option_name = "APEX"
    version     = "20.1.v1"
  }

  option {
    option_name = "APEX-DEV"
  }

  option {
    option_name = "S3_INTEGRATION"

  }

  option {
    option_name = "UTL_MAIL"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "prd-oradb-opt-group"
    }
  )
}

resource "aws_db_subnet_group" "prd-rds-subnet-group" {
  name       = "prd-rds-subnet-group"
  subnet_ids = [aws_subnet.prd-rds-subnet-az1a.id, aws_subnet.prd-rds-subnet-az1b.id]

  tags = merge(
    local.common_tags,
    {
      Name = "prd-rds-subnet-group"
    }
  )
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "prd-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "prd-rds-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_kms_key" "rds" {
  key_id = "alias/aws/rds"
}

resource "aws_db_instance" "prd-nres-rds" {
  allocated_storage         = 2048
  max_allocated_storage     = 4096
  db_name                   = "ORACLEDB"
  storage_type              = "gp3"
  storage_throughput        = 500
  engine                    = "oracle-se2"
  engine_version            = "19.0.0.0.ru-2024-10.rur-2024-10.r1"
  instance_class            = "db.m5.xlarge"
  license_model             = "bring-your-own-license"
  iops                      = 12000
  storage_encrypted         = true
  identifier                = "prd-nres-oradb"
  username                  = var.db_username
  password                  = var.db_password
  option_group_name         = aws_db_option_group.prd-oradb-opt-group.name
  db_subnet_group_name      = aws_db_subnet_group.prd-rds-subnet-group.name
  vpc_security_group_ids    = [aws_security_group.prd-rds-sg.id]
  publicly_accessible       = true # Validate it later stage
  skip_final_snapshot       = true
  final_snapshot_identifier = "prd-oradb-2025-01-17-07-10"
  backup_retention_period   = var.backup_retention_days
  multi_az                  = true
  deletion_protection       = true
  kms_key_id                = data.aws_kms_key.rds.arn
  monitoring_interval       = var.monitoring_interval
  monitoring_role_arn       = aws_iam_role.rds_monitoring_role.arn
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"

  tags = merge(
    local.common_tags,
    {
      Name = "prd-nres-rds"
    }
  )

  lifecycle {
    ignore_changes = [
      username,
      password
    ]
  }
}

/*# WAF Configuration
resource "aws_wafv2_web_acl" "prd-waf" {
  name        = "prd-waf-acl"
  description = "WAF ACL for production environment"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesSQLiRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "IPRateLimit"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "IPRateLimitMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "prd-waf-acl"
    sampled_requests_enabled  = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "prd-waf-acl"
    }
  )
}

resource "aws_cloudwatch_log_group" "prd-waf-log-group" {
  name              = "/aws/waf/prd-waf"
  retention_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Name = "prd-waf-logs"
    }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "prd-waf-logging" {
  log_destination_configs = [aws_cloudwatch_log_group.prd-waf-log-group.arn]
  resource_arn           = aws_wafv2_web_acl.prd-waf.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = "KEEP"
      condition {
        action_condition {
          action = "BLOCK"
        }
      }
      requirement = "MEETS_ANY"
    }
  }
}


# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb-waf-association" {
  resource_arn = aws_lb.prd-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.prd-waf.arn
}
*/

resource "aws_network_acl" "prd-rds-nacl" {
  vpc_id = data.aws_vpc.prd_vpc.id
  subnet_ids = [
    aws_subnet.prd-rds-subnet-az1a.id,
    aws_subnet.prd-rds-subnet-az1b.id
  ]

  # Allow outbound SMTP
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 25
    to_port    = 25
  }

  # Allow return traffic for SMTP
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all other outbound traffic
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all other inbound traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.common_tags,
    {
      Name = "prd-rds-nacl"
    }
  )
}
