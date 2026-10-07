provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "sg" {
  name        = "rocky-linux-sg"
  description = "Security group for Rocky Linux VM"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vm" {
  ami           = "ami-0c4b3a67d08e9e1a7" # Rocky Linux 9.3
  instance_type = "t3.medium"
  key_name      = "your-key-name"
  security_groups = [aws_security_group.sg.name]
  tags = {
    Name = "rocky-linux-vm"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 20
    volume_type = "gp3"
  }
  
  ebs_block_device {
    device_name = "/dev/sdc"
    volume_size = 20
    volume_type = "gp3"
  }
}

