# terraform-aws-ssm-bastion

## Motivation

Accessing databases is an almost vital need for developers.

Traditionally, you would use :
- a bastion in a public subnet, that can route the database,
- a VPN that has a fixed IP (elastic IP/…). The bastion allows outgoing requests from this VPN
- a user management interface, to add or remove some users.
- and you add/remove SSH keys (automatically or using ansible scripts, with cloud Init ... or manually in the worst case)

But It can be complicated:
- remote policies make the management of (remote) office IP more complicated.
- a lot of manual actions may be necessary, especially when companies are growing (managing SSH keys, managing rights, managing users).
- databases are important. Auditing access to the can be critical.
- managing the user management interface (when someone leave, or new hire)
- setting up a VPN can become an hugly backdoor ( let someone rebound from instances to instance due to security breach)

## Goals

Using SSM w/ autoscaling group is much less complicated:
- no more ssh key managements, no more IPs, CIDR block management,
- databases are important. Auditing access to the can be critical. And SSM includes a lot of audits logs out of the box.
- managing new arrivals is just a matter of creating a new user and adding this user to the right group,
- we can manage access rights based on tags, and minimize interactions between instances, and instances with databases. At least privileges first!

In this implementation of SSM:

- the bastions are scheduled for destruction every evening,
- it come back up every morning with the last available AWS AMI,
- and AMIs are encrypted.

## Usage

```HCL
module "private_bastion_demo" {
  source          = "../../"

  region          = "eu-central-1"
  vpc_id          = module.demo_vpc.vpc_id

  # we permit to connect to RDS
  egress_open_ports   = [3306]
  subnet_id       = module.demo_vpc.private_subnets_id[0]
  env             = local.environment
  tags            = local.infrastructure_tags

  access_tag = "QA"
  suffix_name = "demo"
}

```

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | region to deploy the bastion | string | NA | Yes |
| vpc_id | vpc_id to deploy the bastion | string | NA | Yes |
| database_port | database port to link the egress security group | integer | 3306 | No |
| subnet_id | subnet_id to deploy the bastion | string | NA | Yes |
| instance_type | bastion instance type | string | "t2.nano" | No |
| up_recurrence | up recurrence to create the bastion | string | "0 6 * * MON-FRI" | No |
| down_recurrence | down recurrence to destroy the bastion | string | "0 20 * * *" | No |
| egress_open_ports | list of egress ports to open | list(number) | [3306] | No |
| access_tag | define the tag for matching permissions | string | "developer" | No |
| env | environment used in naming | string | NA | Yes |
| tags | global resources tags to add to each resources (useful for billing) | map(string) | NA | No |


## Example

A complete example is available [here](examples/complete), it creates:
- a VPC (on `eu-central-1` aws region)
- a Private Route53 Hosted Zone
- a RDS Instance with dedicated Security Group (and proper private DNS entry)
- a user and a group that can access to the bastion, and RDS Instance as well.

## About Permissions

See [here a complete working example](examples/complete/user.tf) using ABAC.

Attach this kind of document to your users, to permit them to connect to the bastion.

*Note:* the `local.access_value_tag` below should be the same as the access_tag` upper

```HCL
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
```

## Test me !

### Deploy the entire infrastructure
```BASH
cd example/complete
terraform init
terraform apply
# generate a programmatic key from roberto user
# manage credentials into your ~/.aws folder
```

### access it with aws-gate

[Install and configure aws-gate](https://github.com/xen0l/aws-gate)

```BASH
aws-gate ssh -p roberto -L 3386:db-demo.int.demo.com:3306 demo-bastion
```

### or with AWS CLI
```BASH
echo -e 'y\n' | ssh-keygen -t rsa -f /tmp/temp -N '' >/dev/null 2>&1
# fetch the demo-bastion id 
aws ec2-instance-connect send-ssh-public-key --instance-id i-XXXXXXXXXXXX --availability-zone eu-central-1a --instance-os-user ec2-user --ssh-public-key file:///tmp/temp.pub
ssh -i /tmp/temp -Nf -M \
  -L 3376:db-demo.int.demo.com:3306 \
-o "UserKnownHostsFile=/dev/null" \
-o "StrictHostKeyChecking=no" \
-o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p --region=eu-central-1" \
```

### Just test it
```BASH
#In another terminal just make a 
telnet localhost 3386
# And Voila !
```




## License

See [LICENSE](LICENSE) for full details.

