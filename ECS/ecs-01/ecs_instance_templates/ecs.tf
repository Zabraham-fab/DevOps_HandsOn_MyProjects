//This Cloudformation Template creates a Docker machine on EC2 Instance.
//Docker Machine will run on Amazon Linux 2 (ami-026dea5602e368e96) EC2 Instance with
//custom security group allowing SSH connections from anywhere on port 22.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

locals {
  user = "cw-devops"
  pem_file = "clarusway"
}

data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}

resource "aws_instance" "ecs" {
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = local.pem_file
  vpc_security_group_ids = [aws_security_group.ecs-sec-gr.id]
  user_data = file("userdata.sh")
  tags = {
    Name = "${local.user}-ecs-instance"
  }
}

resource "aws_security_group" "ecs-sec-gr" {
  name = "ecs-lesson-sec-gr-${local.user}"
  tags = {
    Name = "ecs-lesson-sec-gr-${local.user}"
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public" {
  value = aws_instance.ecs.public_ip
}