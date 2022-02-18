variable "region" {
  type        = string
  description = "the aws region to use to create the bastion"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "suffix_name" {
  type        = string
  description = "suffix the bastion name, useful quickly retrieve the right bastion for vpc"
}

variable "subnet_id" {
  type        = string
  description = "The subnet where the bastion will be deployed"
}

variable "env" {
  type        = string
  description = "Environment name, staging, beta, production, ..."
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "instance_type" {
  default = "t2.nano"
  type    = string
}

variable "up_recurrence" {
  description = "Up Reccurence"
  type        = string
  default     = "0 6 * * MON-FRI"
}

variable "down_recurrence" {
  description = "Down Reccurence"
  default     = "0 20 * * *"
}

variable "enable_scheduling" {
  description = "Enable scheduling"
  default     = true
}

variable "access_tag" {
  description = "define the tag for permissions"
  default     = "developer"
  type        = string
}

variable "egress_open_ports" {
  type        = list(number)
  default     = [3306]
  description = "List egress open ports for bastions"
}

variable "key_name" {
  default = ""
}

variable "bastion_volume_size" {
  description = "disk volume size for asg bastion instances"
  default     = 10
}
