provider "aws" {
  region = var.aws_region
}

# AMI recherchée dynamiquement chez l'éditeur officiel (Rocky Enterprise
# Software Foundation) au lieu d'un ID codé en dur, propre à une région.
data "aws_ami" "rocky" {
  most_recent = true
  owners      = ["792107900819"]

  filter {
    name   = "name"
    values = ["${var.rocky_ami_name_pattern}.x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Réseau dédié plutôt que le VPC par défaut : celui-ci peut avoir été
# supprimé (c'est le cas sur certains comptes) et ne doit pas porter de
# charges de travail. Pas de NAT Gateway : la VM sort par son IP publique.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "${local.name}-public" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = {
    Name        = local.name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    OS          = "rocky-linux-9"
  }

  lvm_devices = ["/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde"]
}

resource "aws_security_group" "vm" {
  name        = "${local.name}-sg"
  description = "Restricted SSH access for ${local.name}" # ASCII only (contrainte API EC2)
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from admin network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ami.rocky.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vm.id]

  # Création du VG/LV sur les disques dédiés au premier démarrage.
  user_data = templatefile("${path.module}/../../shared/lvm-setup.sh.tftpl", {
    vg_name      = "vg_data"
    lv_name      = "lv_data"
    mount_point  = "/data"
    disk_count   = var.lvm_disk_count
    disk_size_gb = var.lvm_disk_size
  })

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
    tags                  = merge(local.common_tags, { Name = "${local.name}-root" })
  }

  # Deux disques dédiés au LVM, générés dynamiquement au lieu d'être
  # dupliqués bloc par bloc comme dans le fichier d'origine.
  dynamic "ebs_block_device" {
    for_each = { for idx in range(var.lvm_disk_count) : idx => idx }
    content {
      device_name           = local.lvm_devices[ebs_block_device.value]
      volume_size           = var.lvm_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      tags = merge(local.common_tags, {
        Name = "${local.name}-lvm-${ebs_block_device.value + 1}"
      })
    }
  }

  tags = local.common_tags
}
