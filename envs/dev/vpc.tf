//****START MAIN VPC CONFIG****
//This section we can configure the VPC specifics if needed 
resource "aws_vpc" "Example-dev" {
  cidr_block       = "172.42.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "Example-dev"
  }
}

resource "aws_subnet" "public-subnets" {
  for_each = var.public-subnets

  availability_zone = each.value["az"]
  cidr_block        = each.value["cidr"]
  vpc_id            = aws_vpc.Example-dev.id

  tags = {
    Name = "Exampledev-subnet-${each.key}"
  }
}

resource "aws_subnet" "private-subnets" {
  for_each = var.private-subnets

  availability_zone = each.value["az"]
  cidr_block        = each.value["cidr"]
  vpc_id            = aws_vpc.Example-dev.id

  tags = {
    Name = "Exampledev-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.Example-dev.id

  tags = {
    Name = "Example-dev-igw"
  }
}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
  depends_on = [
    aws_internet_gateway.gw
  ]
}

//NAT gateway creation. If needed, we can create more resources
resource "aws_nat_gateway" "nat-gateway-1a" {
  allocation_id = aws_eip.nat_gateway_eip.allocation_id
  subnet_id     = aws_subnet.public-subnets["public-1a"].id
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.Example-dev.id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.Example-dev.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "default-public-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "default-private-route" {
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat-gateway-1a.id
}

resource "aws_route_table_association" "public-route-association" {
  for_each = var.public-subnets

  subnet_id      = aws_subnet.public-subnets["${each.key}"].id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "private-route-association" {
  for_each = var.private-subnets

  subnet_id      = aws_subnet.private-subnets["${each.key}"].id
  route_table_id = aws_route_table.private-route-table.id
}
//****END MAIN VPC CONFIG****

//****START SECURITY GROUPS****
//This section contains all of the security groups used in the VPC.
resource "aws_security_group" "Example-dev-lbs" {
  name        = "Example-dev-lbs"
  description = "Security group for use with load balancers in the public subnets"
  vpc_id      = aws_vpc.Example-dev.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow-https-to-lbs" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Example-dev-lbs.id
}

resource "aws_security_group_rule" "allow-http-to-lbs" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Example-dev-lbs.id
}

resource "aws_security_group" "Example-ecs-dev" {
  name        = "Example-ecs-dev"
  description = "Security group to use for Fargate ECS services"
  vpc_id      = aws_vpc.Example-dev.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow-lbs-to-ecs-http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Example-dev-lbs.id
  security_group_id        = aws_security_group.Example-ecs-dev.id
}
resource "aws_security_group" "Example-dev-postgres" {
  name        = "Example-dev-postgres"
  description = "Security group for use with Postgres databases"
  vpc_id      = aws_vpc.Example-dev.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow-apps-to-postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Example-ecs-dev.id
  security_group_id        = aws_security_group.Example-dev-postgres.id
}
//****END SECURITY GROUPS****