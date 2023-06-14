terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

// Provider config
provider "aws" {
  # TODO: Uncomment these lines and add your own region and path
  # region = "us-east-1"
  # shared_credentials_files = ["Your/Path/Here"]
}

# aws_vpc info
data "aws_vpc" "default" {
  default = true
}

# aws_subnet id
data "aws_subnet_ids" "default" {
  vpc_id = local.vpc_id
}

// Define local variables and find the vpc and subnet ids
locals {
  vpc_id    = length(var.vpc_id) > 0 ? var.vpc_id : data.aws_vpc.default.id
  subnet_id = length(var.subnet_id) > 0 ? var.subnet_id : sort(data.aws_subnet_ids.default.ids)[0]
}

# How to define a security group here
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "main" {
  vpc_id      = local.vpc_id
  name        = "security_group"
  description = "Allow incoming player connections."

  # Standard minecraft port found here 
  # https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server#Firewalling,_NATs_and_external_IP_addresses
  ingress {
    description = "TCP for minecraft"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "Minecraft Security Group"
    Group = "Minecraft"
  }
}

# Actually create the instance
resource "aws_instance" "minecraft_server" {
  # Run the minecraft.sh file on startup of the instance. 
  user_data = file("minecraft.sh")
  subnet_id = local.subnet_id
  # TODO: Specify your region's Amazon Linux AMI here
  ami = "ami-04a0ae173da5807d3"
  # t2.medium is the minimum usable instance_type
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.main.id]
  tags = {
    Name = "Minecraft Final Server"
  }
}

