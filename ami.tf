# Get the latest encrypted amazon 2 AMI
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

# Then copy it and use encryption on it !
resource "aws_ami_copy" "amazon-linux-2-encrypted" {
  name              = "bastion-${data.aws_ami.amazon-linux-2.name}-encrypted"
  description       = "A copy of ${data.aws_ami.amazon-linux-2.description} but encrypted"
  source_ami_id     = data.aws_ami.amazon-linux-2.id
  source_ami_region = var.region
  encrypted         = true
  tags = {
    ImageType = "encrypted-amzn2-linux"
  }
}