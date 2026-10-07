provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = {
    Name        = local.name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    OS          = "rocky-linux-9.3"
  }

  lvm_devices = ["/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde"]
}

resource "aws_security_group" "vm" {
  name        = "${local.name}-sg"
  description = "Accès SSH restreint pour ${local.name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH depuis le réseau d'administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Tout le trafic sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_instance" "vm" {
  ami                    = var.rocky_linux_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.vm.id]

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
