resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "demo_subnets"
  subnet_ids = module.demo_vpc.private_subnets_id
}

resource "aws_db_instance" "demo_db" {
  identifier = "demo-db"

  ## General
  instance_class = "db.t3.micro"
  deletion_protection = false
  skip_final_snapshot = true

  ## Security groups
  vpc_security_group_ids = [aws_security_group.sg_demo_db.id]

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  ## Engine Part
  engine = "mysql"
  engine_version = "5.7.26"
  allocated_storage = 10

  ## root
  username             = "foo"
  password             = "foobarbaz"

  tags = local.infrastructure_tags
}

# Security Group part
resource "aws_security_group" "sg_demo_db" {

  name        = "demo-db"
  description = "Database Security Group"
  vpc_id      = module.demo_vpc.vpc_id

  tags = merge(
  {
    Name = "platform-db"
  },
  local.infrastructure_tags
  )
}

resource "aws_route53_record" "record_db_platform" {
  zone_id = module.private_route53.zone_id
  name    = "db-demo."
  type    = "CNAME"
  ttl     = "3600"
  records = [aws_db_instance.demo_db.address]
}

# Rule to access to the RDS through bastion
resource "aws_security_group_rule" "bastion_sg_rule" {
  from_port = 3306
  protocol = "tcp"
  security_group_id = aws_security_group.sg_demo_db.id
  source_security_group_id = module.private_bastion_demo.this_id_bastion_security_group
  to_port = 3306
  type = "ingress"
}