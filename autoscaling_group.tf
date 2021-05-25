locals {
  instance_name = "bastion-${var.suffix_name}"
  asg_tags = merge(
    var.tags,
    {
      "Name" = "${var.suffix_name}-bastion"
      "Description" = "Bastion based on ${data.aws_ami.amazon-linux-2.name} but encrypted and using SSM capabilities",
      "Access" = var.access_tag
    })
}


resource "aws_launch_configuration" "launch_configuration" {
  name_prefix          = local.instance_name
  image_id             = aws_ami_copy.amazon-linux-2-encrypted.id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.sg_bastion.id]
  iam_instance_profile = module.instance_profile_role.this_iam_role_name
  key_name             = var.key_name

  root_block_device {
    volume_size           = var.bastion_volume_size
    volume_type           = "gp2"
    iops                  = 0
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${local.instance_name}-asg"
  min_size                  = 1
  max_size                  = 1
  force_delete              = false
  vpc_zone_identifier       = [var.subnet_id]
  health_check_grace_period = 300
  health_check_type         = "EC2"
  termination_policies      = ["OldestInstance"]
  launch_configuration      = aws_launch_configuration.launch_configuration.id

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [max_size, min_size]
  }

  dynamic "tag" {
    for_each = local.asg_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# scheduling
resource "aws_autoscaling_schedule" "schedule_work_hours_up" {
  count                  = var.enable_scheduling ? 1 : 0
  scheduled_action_name  = "schedule_work_hours_up"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  autoscaling_group_name = aws_autoscaling_group.asg.name
  recurrence             = var.up_recurrence
}

resource "aws_autoscaling_schedule" "schedule_work_hours_down" {
  count                  = var.enable_scheduling ? 1 : 0
  scheduled_action_name  = "schedule_work_hours_down"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  autoscaling_group_name = aws_autoscaling_group.asg.name
  recurrence             = var.down_reccurence
}