locals {
  cloudinit_config = {
    runcmd = {
      common = [
        # "set -e",
        "yum udpate -y",
        "yum install -y git",
        "git clone git@github.com:accesspc/aws-setup.git /opt/aws-setup",
        "rsync -av /opt/aws-setup/common/* /",
        "systemctl daemon-reload",
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
