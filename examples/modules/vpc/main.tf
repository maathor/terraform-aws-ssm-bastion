variable "letters" {
  description = "a list of letters"
  default = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g"
  ]
}

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = var.resource_name
    }
  )
}

resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.force_public_cidr ? var.public_cidr_blocks_list[count.index] : cidrsubnet(var.vpc_cidr, 4, count.index) # Calculate subnet CIDR
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-public-subnet-${var.letters[count.index]}"
    }
  )
  count = var.max_replication
}

resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.force_private_cidr ? var.private_cidr_blocks_list[count.index] :cidrsubnet(var.vpc_cidr, 4, count.index + length(var.availability_zones)) # Calculate subnet CIDR (add an offset because of public subnets)
  availability_zone = var.availability_zones[count.index]
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-private-subnet-${var.letters[count.index]}"
    }
  )
  count = var.max_replication
}

### Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-igw"
    }
  )
}

resource "aws_route_table" "public_igw_rt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-public-subnet-rt"
    }
  )
}

resource "aws_route_table_association" "public_rt_association" {
  route_table_id = aws_route_table.public_igw_rt.id
  subnet_id      = aws_subnet.public_subnets[count.index].id

  count = var.max_replication
}

resource "aws_nat_gateway" "nat" {
  allocation_id = var.nat_gw_eip_id
  subnet_id     = aws_subnet.public_subnets[var.nat_subnet_id].id # TODO maybe count
  depends_on    = [aws_internet_gateway.igw]
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-nat-gw"
    }
  )
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.default.id
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-private-subnet-rt"
    }
  )
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_rt_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnets[count.index].id

  count = var.max_replication
}

# DHCP Options
resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name         = var.external_base_domain
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = merge(
    var.tags,
    {
      Name = "${var.resource_name}-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "dhcp_options_association" {
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
  vpc_id          = aws_vpc.default.id
}
