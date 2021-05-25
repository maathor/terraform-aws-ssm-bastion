resource "aws_iam_group_policy_attachment" "state_lock_policy_deployers_attach" {
  group      = var.group_name
  policy_arn = aws_iam_policy.ssm_manager_policy.arn
}

resource "aws_iam_policy" "ssm_manager_policy" {
  name        = "SSMManagerPermitAccessTo${var.access_value_tag}Policy"
  path        = "/"
  description = "Permit access for ${var.access_value_tag} Bastion"
  policy = data.aws_iam_policy_document.ssm_access.json
}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    sid = "StartSession"
    effect = "Allow"
    actions = [
      "ssm:StartSession"
    ]
    resources = [
      "arn:aws:ssm:${var.region}::document/AWS-StartSSHSession"
    ]
  }
  statement {
    sid = "StartSessionFromAccessTag"
    effect = "Allow"
    actions = [
      "ssm:StartSession"
    ]
    resources = [
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/i-*"
    ]
    condition {
      test = "ForAnyValue:StringEquals"
      values = [var.access_value_tag]
      variable = "ssm:resourceTag/Access"
    }
  }
  statement {
    sid = "DescribeInstances"
    effect = "Allow"
    actions = [
      "ec2-instance-connect:SendSSHPublicKey",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:DescribeInstanceProperties",
      "ec2:DescribeInstances"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "GetDocument"
    effect = "Allow"
    actions = [
      "ssm:GetDocument",
    ]
    resources = [
      "arn:aws:ssm:::document/SSM-SessionManagerRunShell"
    ]
  }
  statement {
    sid = "TerminateSession"
    effect = "Allow"
    actions = [
      "ssm:TerminateSession",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_caller_identity" "current" {}
