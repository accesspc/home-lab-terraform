provider "aws" {
  default_tags {
    tags = local.default_tags
  }

  profile = "reiciunas"
  region  = "eu-west-2"
}
