terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.72.0"
    }
  }
}

provider "aws" {
  # Configuration options
  profile = "default"
  region  = "eu-west-2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                    = "Kamen_testing-terraform"
  cidr                    = "10.0.0.0/16"
  map_public_ip_on_launch = true

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Name      = "For_testing_210"
    Terraform = true
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

 resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "MyServer Security Group"
  vpc_id      = module.vpc

  ingress = [
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["104.194.51.113/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "outgoing traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  tags = {
    Name      = "For_testing_210"
    Terraform = true
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7kQM4l9oVCU9OIQjFJo/0P04VXLe84g5vT85blYXaNq5N7La3XruHsz0G8axS3YB2ohK2zLrSrPU7CHJ+4aa0WWyt7nVxgmIE+5LK0eewfMhhfxgL9dnsxUITkTaUmR+DhX+C6hTeVx+lg1azY0WFEvYEqynaMReuAFtjK4DzlGxIFe6SRXEUhB6qf9pKUi4ouefn/VbanzWfTmpv2uNB/Wv9nMJRdZcsDGTEHcSoRr/cfH/TxX3piEtORhBPdS+BxkXNtA55b3RyuZJPfUZh78odYHrSTEYZ4+nFjSErRe8FNenVHCavhiPaBEbAogeKQAy51TZBAwycFq+om+x3"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  count                       = 2
  #   cpu_options {
  #     core_count       = 2
  #     threads_per_core = 2
  #   }

  tags = {
    Name      = "For_testing_210-${count.index + 1}" # Add 1 to make it 1-indexed
    Index     = count.index + 1                      # Adding 1 to make it 1-indexed
    Terraform = true
  }
}

output "web_public_ip" {
  value = aws_instance.web[*].public_ip
}

resource "local_file" "save_public_ips" {
  content  = join("\n,", aws_instance.web[*].public_ip)
  filename = "${path.root}/public_ips.txt"
}
