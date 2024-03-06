locals {
  cloudinit_config = {
    runcmd = {
      common = [
        # "set -e",
        "yum udpate -y",
        "yum install -y git",
        "git clone git@github.com:accesspc/aws-setup.git /opt/aws-setup",
        "rsync -av /opt/aws-setup/common/* /",
        "/bin/bash /opt/scripts/setup.sh",
      ]
    }

    write_files = [
      {
        content     = base64encode(var.git_ssh_key)
        encoding    = "b64"
        path        = "/root/.ssh/id_rsa"
        permissions = "0600"
        }, {
        content     = base64encode(var.git_ssh_known_hosts)
        encoding    = "b64"
        path        = "/root/.ssh/known_hosts"
        permissions = "0600"
      }
    ]
  }
}

resource "aws_key_pair" "default" {
  key_name   = var.prefix
  public_key = var.aws_key_pair_public_key
}

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
    "${jsondecode(data.http.my_ip.response_body).ip}/32",
    "${aws_eip.vpn.public_ip}/32"
  ]

  description       = "SSH"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.mgmt.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "mgmt_ingress_self" {
  description       = "Self"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.mgmt.id
  self              = true
  to_port           = 0
  type              = "ingress"
}
