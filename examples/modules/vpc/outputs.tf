output "vpc_id" {
  value = aws_vpc.default.id
}

output "public_subnets_id" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnets_id" {
  value = aws_subnet.private_subnets.*.id
}

output "private_route_table" {
  value = aws_route_table.private_route_table.id
}
