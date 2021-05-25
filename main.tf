module "instance_profile_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 3.0"

  role_name               = "${lower(var.suffix_name)}-bastion-instance-role-${lower(var.env)}"
  create_role             = true
  create_instance_profile = true
  role_requires_mfa       = false

  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/EC2InstanceConnect",
  ]
}


# Allow all outgoing HTTP and HTTPS traffic, as well as communication to db
resource "aws_security_group" "sg_bastion" {
  name        = "${var.suffix_name}-bastion-${var.env}"
  description = "Allow all outgoing HTTP and HTTPS traffic, as well as communication to db"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.suffix_name}-bastion-${var.env}-instance"
      Description = "${var.suffix_name} Bastion based on ${data.aws_ami.amazon-linux-2.name} but encrypted",
    }
  )
}

resource "aws_security_group_rule" "egress_open_ports" {
  count             = length(var.egress_open_ports)
  from_port         = var.egress_open_ports[count.index]
  protocol          = "tcp"
  security_group_id = aws_security_group.sg_bastion.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = var.egress_open_ports[count.index]
  type              = "egress"
}

resource "aws_security_group_rule" "egress_ssm" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sg_bastion.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 443
  type              = "egress"
  description       = "allow outgoing HTTPS traffic (useful to perform ssm endpoint traffic)"
}

resource "aws_security_group_rule" "egress_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.sg_bastion.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 80
  type              = "egress"
  description       = "allow outgoing HTTP traffic (useful for update and install)"
}