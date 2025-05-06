# Its region specific | 5 per region

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0" # ~> before the version number ... means can only take updates from the SECOND number 19 so >19 but not less than 20..

  name            = var.vpc_name
  cidr            = "172.30.0.0/16"                    # 65,536 IPs
  private_subnets = ["172.30.1.0/28", "172.30.2.0/28"] # Access to the public internet from a private subnet requires A NAT device - $$$$
  public_subnets  = ["172.30.3.0/28", "172.30.4.0/28"]

  enable_vpn_gateway = false
  enable_nat_gateway = false # Turned off != free tier

  enable_dns_hostnames = true
  enable_dns_support   = true
  single_nat_gateway   = true
  azs                  = ["us-east-1a", "us-east-1b"]
}

output "vpc_id" {
  value = module.vpc.default_vpc_id
}