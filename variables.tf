variable "aws_region" {
  description = "Default region for provider"
  type        = string
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_cidr" {
  description = "IP address allowed to SSH"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
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