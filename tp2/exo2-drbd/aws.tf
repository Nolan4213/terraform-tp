data "aws_ami" "rocky" {
  most_recent = true
  owners      = ["792107900819"] # Rocky Enterprise Software Foundation

  filter {
    name   = "name"
    values = ["Rocky-9-EC2-Base-9.*.x86_64"]
  }
}

# Réseau minimal et gratuit : VPC + subnet public + Internet Gateway.
# Pas de NAT Gateway (≈ 35 $/mois) : l'instance sort directement par son IP publique.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "${var.project_name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.project_name}-key"
  public_key = local.ssh_public_key
}

resource "aws_eip" "node" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-aws-ip" }
}

resource "aws_security_group" "node" {
  name        = "${var.project_name}-aws-sg"
  description = "SSH admin + DRBD depuis le pair Azure uniquement"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-aws-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.node.id
  description       = "SSH administration"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.admin_cidr
}

resource "aws_vpc_security_group_ingress_rule" "drbd" {
  security_group_id = aws_security_group.node.id
  description       = "Replication DRBD depuis le pair Azure"
  ip_protocol       = "tcp"
  from_port         = var.drbd_port
  to_port           = var.drbd_port
  cidr_ipv4         = "${azurerm_public_ip.node.ip_address}/32"
}

resource "aws_vpc_security_group_ingress_rule" "icmp" {
  security_group_id = aws_security_group.node.id
  description       = "Ping depuis le pair Azure"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = "${azurerm_public_ip.node.ip_address}/32"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.node.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "node" {
  ami                    = data.aws_ami.rocky.id
  instance_type          = var.aws_instance_type
  key_name               = aws_key_pair.admin.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.node.id]

  # Le mode "unlimited" (défaut des t3) facture le CPU au-delà des crédits.
  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.data_disk_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/drbd-node.sh.tftpl", merge(local.drbd_common, {
    node_name = local.drbd_common.aws_name
    public_ip = local.drbd_common.aws_ip
    role      = "primary"
  }))

  tags = { Name = "${var.project_name}-aws" }
}

resource "aws_eip_association" "node" {
  # L'IGW doit exister pour que l'EIP soit routable.
  depends_on = [aws_internet_gateway.main]

  instance_id   = aws_instance.node.id
  allocation_id = aws_eip.node.id
}
