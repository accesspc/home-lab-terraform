resource "aws_security_group" "mgmt" {
  name        = "${var.prefix}-MGMT-SG01"
  description = "${var.prefix}-MGMT-SG01"

  tags = {
    Name = "${var.prefix}-MGMT-SG01"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "mgmt_egress" {
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  description       = "Egress"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.mgmt.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "mgmt_ingress_ssh" {
  cidr_blocks = [
    "${jsondecode(data.http.myip.response_body).ip}/32",
    "${aws_eip.vpn.public_ip}/32"
  ]

  description       = "SSH"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.mgmt.id
  to_port           = 22
  type              = "ingress"
}
