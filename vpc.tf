resource "aws_vpc" "default" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "${var.prefix}-VPC"
  }
}

resource "aws_internet_gateway" "default" {
  tags = {
    Name = "${var.prefix}-IGW"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "private" {
  count = 3

  availability_zone = local.config.vpc.zones[count.index]

  cidr_block = cidrsubnet(
    var.aws_vpc_cidr, 4, count.index
  )

  tags = {
    Name = "${var.prefix}-Private-${local.config.vpc.zones[count.index]}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "public" {
  count = 3

  availability_zone = local.config.vpc.zones[count.index]

  cidr_block = cidrsubnet(
    var.aws_vpc_cidr, 4, count.index + 4
  )

  tags = {
    Name = "${var.prefix}-Public-${local.config.vpc.zones[count.index]}"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_route" "igw" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  tags = {
    Name = "${var.prefix}-RT"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public" {
  tags = {
    Name = "${var.prefix}-RT"
  }

  vpc_id = aws_vpc.default.id
}

resource "aws_route_table_association" "private" {
  count = 3

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_route_table_association" "public" {
  count = 3

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}
