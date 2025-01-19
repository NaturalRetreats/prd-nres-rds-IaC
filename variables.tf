variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "listener_subnet_1a_cidr" {
  description = "CIDR block for Listener subnet in AZ 1a"
  type        = string
  default     = "172.31.112.0/20"
}

variable "listener_subnet_1b_cidr" {
  description = "CIDR block for Listener subnet in AZ 1b"
  type        = string
  default     = "172.31.128.0/20"
}

variable "rds_subnet_1a_cidr" {
  description = "CIDR block for RDS subnet in AZ 1a"
  type        = string
  default     = "172.31.80.0/20"
}

variable "rds_subnet_1b_cidr" {
  description = "CIDR block for RDS subnet in AZ 1b"
  type        = string
  default     = "172.31.96.0/20"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "Oracle Migration and Modernization to AWS RDS"
}

variable "db_username" {
  description = "Username for the RDS Oracle database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the RDS Oracle database"
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

/*variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
}*/

variable "backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 30
  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 0 and 35"
  }
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 60
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60"
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "hdesai@parkar.digital"
    Owner       = "Parkar Team"
    CreatedBy   = "hdesai@parkar.digital"
    CreatedOn   = "January 2025"
  }
}
