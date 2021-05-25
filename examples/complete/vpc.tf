locals {
  infrastructure_tags = merge(
  {
    Domain = "Demo"
    Environment = local.environment
  })
  environment = "Staging"
  region      = "eu-central-1"
}

# Create a Test VPC
data "aws_availability_zones" "available" {}

# eIP for VPC
resource "aws_eip" "vpc_eip" {}

# let's create a VPC
module "demo_vpc" {
  source = "../modules/vpc"

  resource_name = "Demo"
  vpc_cidr      = "172.31.0.0/16"

  availability_zones = data.aws_availability_zones.available.names

  nat_gw_eip_id = aws_eip.vpc_eip.id
  nat_subnet_id = "0"

  external_base_domain = "int.demo.com"

  tags    = local.infrastructure_tags
}

# Create a private route53 for this VPC
module "private_route53" {
  source = "../modules/private_route53_zone"

  name        = "int.demo.com"
  environment = local.environment
  main_vpc    = module.demo_vpc.vpc_id
  force_destroy = false
}