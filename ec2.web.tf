locals {
  cloudinit_web = {
    runcmd = concat(
      local.cloudinit_config.runcmd.common,
      [
        # Restore
        "rsync -av /opt/home-lab-setup/web/* /",
        "bash /opt/home-lab-setup/scripts/web-restore.sh ${aws_instance.mysql.private_ip}",
      ]
    )

    write_files = local.cloudinit_config.write_files
  }
}

data "cloudinit_config" "web" {
  base64_encode = true
  gzip          = true

  part {
    content      = yamlencode(local.cloudinit_web)
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id

  tags = {
    Name = "${var.prefix}-Web01"
    Type = "Web"
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.prefix}-EC2-Web-role"
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
    Name = "${var.prefix}-EC2-Web-role"
    Type = "Web"
  }
}

resource "aws_iam_role_policy" "web" {
  name = "${var.prefix}-EC2-Web-policy"
  role = aws_iam_role.web.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectTagging",
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

resource "aws_iam_role_policy_attachment" "web_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.web.id
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.prefix}-EC2-Web-profile"
  role = aws_iam_role.web.name
}

resource "aws_instance" "web" {
  depends_on = [
    aws_instance.mysql
  ]

  ami                  = data.aws_ami.default.id
  ebs_optimized        = true
  iam_instance_profile = aws_iam_instance_profile.web.name
  instance_type        = var.aws_ec2_instance_type_web
  key_name             = aws_key_pair.default.key_name

  root_block_device {
    volume_size = 16
  }

  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.prefix}-Web01"
    Type = "Web"
  }

  user_data = data.cloudinit_config.web.rendered

  vpc_security_group_ids = [
    aws_security_group.mgmt.id,
    aws_security_group.web.id
  ]

  volume_tags = {
    Name = "${var.prefix}-Web01"
    Type = "Web"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.prefix}-Web-SG01"
  description = "${var.prefix}-Web-SG01"

  tags = {
    Name = "${var.prefix}-Web-SG01"
    Type = "Web"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "web_egress" {
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  description       = "Egress"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.web.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "web_ingress_http" {
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  description       = "HTTP"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.web.id
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "web_ingress_https" {
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  description       = "HTTPS"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.web.id
  to_port           = 443
  type              = "ingress"
}

output "web_private" {
  value = aws_instance.web.private_ip
}

output "web_public" {
  value = aws_eip.web.public_ip
}
