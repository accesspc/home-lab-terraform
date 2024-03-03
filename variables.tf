variable "aws_key_pair_public_key" {
  description = "AWS Key Pair: Public key"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR"
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
