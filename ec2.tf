locals {
  cloudinit_config = {
    runcmd = [
      "dnf udpate -y",
      # node exporter
      "wget -O /tmp/node_exporter.tgz https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-arm64.tar.gz",
      "tar -xf /tmp/node_exporter.tgz -C /tmp",
      "mv -f /tmp/node_exporter-1.7.0.linux-arm64/node_exporter /usr/local/bin",
      "useradd -M -s /bin/false prometheus",
      "systemctl enable --now prometheus-node-exporter.service",
      # tailscale
      "curl -fsSL https://tailscale.com/install.sh | sh",
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

resource "aws_security_group_rule" "mgmt_ingress_self" {
  description       = "Self"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.mgmt.id
  self              = true
  to_port           = 0
  type              = "ingress"
}
