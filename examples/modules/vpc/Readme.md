# Terraform VPC module

## Synopsis
This module creates a VPC with the following components:
- a VPC with the specified CIDR
- 3 public subnets (up to 4k adresses per subnet)
- 3 private subnets (up to 4k adresses per subnet)
- IGW
- Nat GW
- routing tables

 ## Usage
A sample usage:
```terraform
module "vpc_module" {
  source = "../modules/vpc"

  resource_name = "${var.global_name}"
  vpc_cidr = "${var.vpc_cidr}"
  availability_zones = ["${data.aws_availability_zones.available.names}"]
  nat_subnet_id = "${var.nat_subnet_id}"
}
```

## Parameters
- `resource_name`: prefix resource name
- `vpc_cidr`: expected vpc
- `availability_zones`: List of AZ for the region (should be defined using datasource as shown in the example)
- `nat_subnet_id`: A value between 0 and count(AZ) - 1. This can be useful in case of outage on an AZ. In this case, change this value to spawn the nat in another subnet

## Outputs
- `vpc_id`: ID of the vpc
- `public_subnets_id`: List of id for public subnets
- `private_subnets_id`: List of id for private subnets