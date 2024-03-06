locals {
  config = {
    vpc = {
      zones = [
        "eu-west-2a",
        "eu-west-2b",
        "eu-west-2c"
      ]
    }
  }

  default_tags = {
    Build       = "Terraform"
    Environment = "Production"
  }
}

data "aws_ami" "default" {
  filter {
    name = "name"

    values = [
      "al2023-ami-2023*"
    ]
  }

  filter {
    name = "architecture"

    values = [
      "arm64"
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm"
    ]
  }

  most_recent = true

  owners = [
    "amazon"
  ]
}

data "http" "my_ip" {
  url = "https://ipinfo.io"
}
