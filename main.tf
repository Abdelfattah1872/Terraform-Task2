data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "pvt-instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnets["private"].id
  vpc_security_group_ids      = [aws_security_group.sg-pvt.id]
  associate_public_ip_address = false
  user_data                   = file("apache.sh")
  tags = { Name = "pvt-apache-bastion" }
}

resource "aws_instance" "pub-instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnets["public"].id
  vpc_security_group_ids      = [aws_security_group.sg-pub.id]
  associate_public_ip_address = true
  user_data                   = file("apache.sh")
  tags = { Name = "pub-apache-bastion" }
}

#######################NETWORK####################


resource "aws_vpc" "vpc" {
  cidr_block = var.cidrs["vpc"]
  tags = { Name = "tf-bastion" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = { Name= "igw-bastion" }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnets["public"].id
  depends_on    = [aws_internet_gateway.igw]
  tags = { Name = "nat-bastion" }
}

resource "aws_subnet" "subnets" {
  for_each = var.subnet_cidrs
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value
  tags = {Name = "${each.key}-subnet-bastion"}
}


#######################ROUTETABLES####################


resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.cidrs["route-table"]
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table-bastion" }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "private-route-table-bastion" }
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = var.cidrs["route-table"]
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "pub-rt-association" {
  subnet_id      = aws_subnet.subnets["public"].id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "pvt-rt-association" {
  subnet_id      = aws_subnet.subnets["private"].id
  route_table_id = aws_route_table.private-route-table.id
}

#######################Securirty Groups####################


resource "aws_security_group" "sg-pub" {
  vpc_id      = aws_vpc.vpc.id
ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }
egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-pub-bastion" }
}

resource "aws_security_group" "sg-pvt" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidrs["public"]]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-pvt-bastion" }
}