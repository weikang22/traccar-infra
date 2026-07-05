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