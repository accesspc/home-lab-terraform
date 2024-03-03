resource "aws_key_pair" "default" {
  key_name   = var.prefix
  public_key = var.aws_key_pair_public_key
}
