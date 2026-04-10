variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "deploy_role_arn" {
  description = "ARN of the IAM role to assume for deployment"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "marcuspaula-cloudsec"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "secure-terraform-pipeline"
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "security-terraform-state"
}

variable "lock_table" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "terraform-locks"
}
