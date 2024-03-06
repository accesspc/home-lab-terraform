locals {
  cloudinit_vpn = {
    runcmd = concat(
      local.cloudinit_config.runcmd.common,
      [
        # NAT
        "iptables -t nat -A POSTROUTING -o $(ls -1 /sys/class/net/ | grep -v lo | grep -v tailscale) -s ${var.aws_vpc_cidr} -j MASQUERADE",
        # tailscale
        "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf",
        "echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf",
        "sysctl -p",
        "tailscale up --auth-key ${var.ts_auth_key} --hostname aws --accept-routes --advertise-exit-node --advertise-routes=${var.aws_vpc_cidr} --accept-routes",
      ]
    )

    write_files = local.cloudinit_config.write_files
  }
}

data "cloudinit_config" "vpn" {
  base64_encode = true
  gzip          = true

  part {
    content      = yamlencode(local.cloudinit_vpn)
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

resource "aws_iam_role" "vpn" {
  name               = "${var.prefix}-EC2-VPN-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = {
    Name = "${var.prefix}-EC2-VPN-role"
  }
}

resource "aws_iam_role_policy" "vpn" {
  name = "${var.prefix}-EC2-VPN-policy"
  role = aws_iam_role.vpn.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListMultipartUploadParts",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.aws_s3_bucket}",
        "arn:aws:s3:::${var.aws_s3_bucket}/*"
      ],
      "Sid": "SidObjects0"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "vpn" {
  name = "${var.prefix}-EC2-VPN-profile"
  role = aws_iam_role.vpn.name
}

resource "aws_instance" "vpn" {
  ami                  = data.aws_ami.default.id
  ebs_optimized        = true
  iam_instance_profile = aws_iam_instance_profile.vpn.name
  instance_type        = var.aws_ec2_instance_type_vpn
  key_name             = aws_key_pair.default.key_name
  source_dest_check    = false
  subnet_id            = aws_subnet.public[0].id

  tags = {
    Name = "${var.prefix}-VPN01"
  }

  user_data = data.cloudinit_config.vpn.rendered

  vpc_security_group_ids = [
    aws_security_group.mgmt.id,
    aws_security_group.vpn.id
  ]

  volume_tags = {
    Name = "${var.prefix}-VPN01"
  }
}

resource "aws_security_group" "vpn" {
  name        = "${var.prefix}-VPN-SG01"
  description = "${var.prefix}-VPN-SG01"

  tags = {
    Name = "${var.prefix}-VPN-SG01"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "vpn_egress" {
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  description       = "Egress"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.vpn.id
  to_port           = 0
  type              = "egress"
}

output "vpn_private" {
  value = aws_instance.vpn.private_ip
}

output "vpn_public" {
  value = aws_eip.vpn.public_ip
}
