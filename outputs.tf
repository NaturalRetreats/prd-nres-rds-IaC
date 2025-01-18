# VPC and Networking
output "vpc_id" {
  description = "The ID of the VPC"
  value       = data.aws_vpc.prd_vpc.id
}

output "listener_subnet_1a_id" {
  description = "The ID of listener subnet in AZ 1a"
  value       = aws_subnet.prd-listener-subnet-az1a.id
}

output "listener_subnet_1b_id" {
  description = "The ID of listener subnet in AZ 1b"
  value       = aws_subnet.prd-listener-subnet-az1b.id
}

# Security Groups
output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.prd-alb-sg.id
}

output "ec2_security_group_id" {
  description = "The ID of the EC2 security group"
  value       = aws_security_group.prd-ec2-sg.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.prd-rds-sg.id
}

# Load Balancer
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.prd-nres-alb.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB"
  value       = aws_lb.prd-nres-alb.zone_id
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.prd-nres-alb.arn
}

/*output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}*/

# RDS
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.prd-nres-rds.endpoint
}

output "rds_subnet_group_name" {
  description = "The name of the RDS subnet group"
  value       = aws_db_subnet_group.prd-rds-subnet-group.name
}

output "rds_monitoring_role_arn" {
  description = "The ARN of the RDS enhanced monitoring IAM role"
  value       = aws_iam_role.rds_monitoring_role.arn
}

# WAF
/*output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.prd-waf.id
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.prd-waf.arn
}

output "waf_log_group_name" {
  description = "The name of the WAF CloudWatch log group"
  value       = aws_cloudwatch_log_group.prd-waf-log-group.name
}

output "waf_logging_configuration_id" {
  description = "The ID of the WAF logging configuration"
  value       = aws_wafv2_web_acl_logging_configuration.prd-waf-logging.id
}*/

# DMS
output "dms_subnet_group_id" {
  description = "The ID of the DMS replication subnet group"
  value       = aws_dms_replication_subnet_group.prd-dms-subnet-grp.id
}
