locals {
  vpn_cloudinit_config = {
    runcmd = concat([
      "yum udpate -y",
      # tailscale
      "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf",
      "echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf",
      "sysctl -p",
      "curl -fsSL https://tailscale.com/install.sh | sh",
      "tailscale up --auth-key ${var.ts_auth_key} --hostname aws --accept-routes --advertise-exit-node --advertise-routes=${var.aws_vpc_cidr} --accept-routes",
      # node exporter
      "wget -O /tmp/node_exporter.tgz https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-arm64.tar.gz",
      "tar -xf /tmp/node_exporter.tgz -C /tmp",
      "mv -f /tmp/node_exporter-1.7.0.linux-arm64/node_exporter /usr/local/bin",
      "useradd -M -s /bin/false prometheus",
      "systemctl enable --now prometheus-node-exporter.service",
    ])

    write_files = [
      {
        content  = base64encode(file("${path.module}/files/prometheus-node-exporter.service"))
        encoding = "b64"
        path     = "/etc/systemd/system/prometheus-node-exporter.service"
      }
    ]
  }
}

data "cloudinit_config" "vpn" {
  base64_encode = true
  gzip          = true

  part {
    content      = yamlencode(local.vpn_cloudinit_config)
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

resource "aws_eip" "vpn" {
  domain   = "vpc"
  instance = aws_instance.vpn.id

  tags = {
    Name = "${var.prefix}-VPN01"
  }
}

resource "aws_instance" "vpn" {
  ami = data.aws_ami.default.id

  ebs_optimized = true
  instance_type = "t4g.micro"

  key_name = aws_key_pair.default.key_name

  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.prefix}-VPN01"
  }

  user_data = data.cloudinit_config.vpn.rendered

  vpc_security_group_ids = [
    aws_security_group.mgmt.id
  ]
}
