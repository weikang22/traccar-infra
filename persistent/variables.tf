variable "project_name" {
  description = "Project name"
  type        = string
  default     = "traccar"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Default region for provider"
  type        = string
  default     = "eu-west-2"
}

variable "availability_zone" {
  description = "Availability zone for the EBS volume"
  type        = string
  default     = "eu-west-2a"
}

variable "ebs_volume_size" {
  description = "Size of EBS volume"
  type        = number
  default     = 8
}

variable "ebs_volume_type" {
  description = "Type of EBS volume"
  type        = string
  default     = "gp3"
}