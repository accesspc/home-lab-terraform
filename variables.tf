variable "aws_ec2_instance_type_mysql" {
  description = "AWS EC2 Instance Type: MySQL"
  type        = string
}

variable "aws_ec2_instance_type_vpn" {
  description = "AWS EC2 Instance Type: VPN"
  type        = string
}

variable "aws_ec2_instance_type_web" {
  description = "AWS EC2 Instance Type: Web"
  type        = string
}

variable "aws_key_pair_public_key" {
  description = "AWS Key Pair: Public key"
  type        = string
}

variable "aws_s3_bucket" {
  description = "S3 bucket for backups"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
}

variable "git_ssh_key" {
  description = "Git SSH Key"
  type        = string
}

variable "git_ssh_known_hosts" {
  description = "Git SSH Known Hosts"
  type        = string
}

variable "prefix" {
  description = "Name prefix"
  type        = string
}

variable "ts_auth_key" {
  description = "Tailscale auth key"
  type        = string
}
