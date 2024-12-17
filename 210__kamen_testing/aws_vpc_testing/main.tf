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
