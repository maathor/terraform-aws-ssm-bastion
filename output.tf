output "this_id_bastion_security_group" {
  description = "id of the bastion security group"
  value       = aws_security_group.sg_bastion.id
}

output "this_arn_bastion_security_group" {
  description = "id of the bastion security group"
  value       = aws_security_group.sg_bastion.arn
}
