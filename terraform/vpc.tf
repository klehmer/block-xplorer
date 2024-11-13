data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.15.0"

  name = "block-xplorer-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# Create a route table
resource "aws_route_table" "egress_route_table" {
  vpc_id = module.vpc.vpc_id

  # Route all outbound traffic (0.0.0.0/0) through the NAT gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = module.vpc.natgw_ids.0
  }

  tags = {
    Name = "egress-route-table"
  }
}

# Associate the route table with each private subnet
resource "aws_route_table_association" "rt_subnet_associations" {
  for_each       = toset(module.vpc.private_subnets)
  subnet_id      = each.value
  route_table_id = aws_route_table.egress_route_table.id
}
