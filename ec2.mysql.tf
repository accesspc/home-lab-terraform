locals {
  cloudinit_mysql = {
    runcmd = concat(
      local.cloudinit_config.runcmd.common,
      [
        # Restore
        "rsync -av /opt/home-lab-setup/mysql/* /",
        "bash /opt/home-lab-setup/scripts/mysql-restore.sh",
      ]
    )

    write_files = local.cloudinit_config.write_files
  }
}

data "cloudinit_config" "mysql" {
  base64_encode = true
  gzip          = true

  part {
    content      = yamlencode(local.cloudinit_mysql)
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

resource "aws_iam_role" "mysql" {
  name               = "${var.prefix}-EC2-MySQL-role"
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
    Name = "${var.prefix}-EC2-MySQL-role"
    Type = "MySQL"
  }
}

resource "aws_iam_role_policy" "mysql" {
  name = "${var.prefix}-EC2-MySQL-policy"
  role = aws_iam_role.mysql.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
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

resource "aws_iam_role_policy_attachment" "mysql_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.mysql.id
}

resource "aws_iam_instance_profile" "mysql" {
  name = "${var.prefix}-EC2-MySQL-profile"
  role = aws_iam_role.mysql.name
}

resource "aws_instance" "mysql" {
  ami                         = data.aws_ami.al2023.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.mysql.name
  instance_type               = var.aws_ec2_instance_type_mysql
  key_name                    = aws_key_pair.default.key_name

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  subnet_id = aws_subnet.private[0].id

  tags = {
    Name = "${var.prefix}-MySQL01"
    Type = "MySQL"
  }

  user_data = data.cloudinit_config.mysql.rendered

  vpc_security_group_ids = [
    aws_security_group.mgmt.id,
    aws_security_group.mysql.id
  ]

  volume_tags = {
    Name = "${var.prefix}-MySQL01"
    Type = "MySQL"
  }
}

resource "aws_security_group" "mysql" {
  name        = "${var.prefix}-MySQL-SG01"
  description = "${var.prefix}-MySQL-SG01"

  tags = {
    Name = "${var.prefix}-MySQL-SG01"
    Type = "MySQL"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "mysql_egress" {
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  description       = "Egress"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.mysql.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "mysql_ingress_mysql" {
  description              = "MySQL"
  from_port                = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mysql.id
  source_security_group_id = aws_security_group.web.id
  to_port                  = 3306
  type                     = "ingress"
}

output "mysql_private" {
  value = aws_instance.mysql.private_ip
}
