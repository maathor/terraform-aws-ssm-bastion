module "private_bastion_demo" {
  source          = "../../"

  region          = "eu-central-1"
  vpc_id          = module.demo_vpc.vpc_id

  # we permit to connect to RDS
  egress_open_ports   = [3306]
  subnet_id       = module.demo_vpc.private_subnets_id[0]
  env             = local.environment
  tags            = local.infrastructure_tags

  access_tag = "QA"
  suffix_name = "demo"
}