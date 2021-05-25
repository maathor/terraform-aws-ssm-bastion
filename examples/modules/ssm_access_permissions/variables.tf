variable "region" {
  description = "region to bind"
}

variable "env" {
  description = "environment to bind"
}

variable "access_value_tag" {
  description = "define which instances defined with Access Tag to permit access"
}

variable "group_name" {
  description = "group to attach ssm role"
}