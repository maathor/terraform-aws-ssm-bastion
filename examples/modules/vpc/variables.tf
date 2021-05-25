variable "resource_name" {
  description = "name of the resource"
}

variable "external_base_domain" {
  description = "The external domain for this enviornment"
  default = ""
}

variable "internal_base_domain" {
  description = "The internal domain for this enviornment"
  default = ""
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
}
variable "force_public_cidr" {
  type = bool
  description = "use already created cidr block"
  default = false
}

variable "public_cidr_blocks_list" {
  type = list(string)
  description = "CIDR block to use by subnets"
  default = ["172.30.0.0/24","172.30.1.0/24","172.30.2.0/24"]
}

variable "force_private_cidr" {
  type = bool
  description = "force use cidr block"
  default = false
}

variable "private_cidr_blocks_list" {
  type = list(string)
  description = "CIDR block to use by subnets"
  default = ["172.30.0.0/24","172.30.1.0/24","172.30.2.0/24"]
}

variable "availability_zones" {
  description = "number of replicated zone"
  type        = list(string)
}

variable "max_replication" {
  description = "region can contains a lot of replication zone, but we mostly need to have fewer replication"
  default = 3
  type = number
}

variable "nat_subnet_id" {
  description = "Identifies the subnet where the NAT Gateway will be deployed. Between 0 and Number of Availability Zones"
}

variable "nat_gw_eip_id" {
  description = "NAT Gateway EIP allocation ID"
}

variable "peer_vpc_id" {
  description = "vpc id of peered"
  default     = ""
}

variable "tags" {
  description = "Resouce tags"
  type        = map(string)
}

variable "dopt_id" {
  description = "force to use a dhcp"
  type = string
  default = ""
}