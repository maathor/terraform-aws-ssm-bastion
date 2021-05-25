locals {
  access_tag_key = "Access"
  access_tag_value = "QA"
}

// Roberto is a QA in the Demo Corp.
resource "aws_iam_user" "roberto" {
  name = "roberto"
  path = "/"
}

// Roberto is on QA Group
resource "aws_iam_group" "ssm_group" {
  name = "DemoQASSMAccess"
  path = "/"
}

resource "aws_iam_group_membership" "ssm_membership_production" {
  name = "demo-ssm-membership"
  users = [
    aws_iam_user.roberto.name
  ]
  group = aws_iam_group.ssm_group.id
}

resource "aws_iam_group_policy_attachment" "state_lock_policy_deployers_attach" {
  group      = aws_iam_group.ssm_group.name
  policy_arn = aws_iam_policy.ssm_manager_policy.arn
}

resource "aws_iam_policy" "ssm_manager_policy" {
  name        = "SSMManagerPermitAccessTo${local.access_tag_value}Policy"
  path        = "/"
  description = "Permit access for ${local.access_tag_value} Bastion"
  policy = data.aws_iam_policy_document.ssm_access.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    sid = "StartSession"
    effect = "Allow"
    actions = [
      "ssm:StartSession"
    ]
    resources = [
      "arn:aws:ssm:${local.region}::document/AWS-StartSSHSession"
    ]
  }
  statement {
    sid = "StartSessionFromAccessTag"
    effect = "Allow"
    actions = [
      "ssm:StartSession",
      "ec2-instance-connect:SendSSHPublicKey"
    ]
    resources = [
      "arn:aws:ec2:${local.region}:${data.aws_caller_identity.current.account_id}:instance/i-*"
    ]
    condition {
      test = "ForAnyValue:StringEqualsIfExists"
      values = [local.access_tag_value]
      variable = "ssm:resourceTag/${local.access_tag_key}"
    }
  }
  statement {
    sid = "DescribeInstances"
    effect = "Allow"
    actions = [
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