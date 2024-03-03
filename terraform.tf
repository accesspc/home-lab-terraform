terraform {
  backend "s3" {
    bucket  = "reiciunas.state"
    key     = "home-lab/terraform.json"
    profile = "reiciunas"
    region  = "eu-west-2"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    http = {
      source = "hashicorp/http"
    }
  }

  required_version = ">= 1.3.0"
}
