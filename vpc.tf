# Its region specific | 5 per region
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0" # ~> before the version number ... means can only take updates from the SECOND number 19 so >19 but not less than 20..

  name            = var.vpc_name
  cidr            = "172.30.0.0/16"                    # 65,536 IPs
  private_subnets = ["172.30.1.0/25", "172.30.1.128/25"] # Access to the public internet from a private subnet requires A NAT device - $$$$
  public_subnets  = ["172.30.2.0/25", "172.30.2.128/25"]

  enable_vpn_gateway = false
  enable_nat_gateway = false  # Turned off != free tier

  enable_dns_hostnames = true
  enable_dns_support   = true
  single_nat_gateway   = false # Cost so leave off
  azs                  = ["us-east-1a", "us-east-1b"]

  #Added flow logs
  enable_flow_log = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_destination_type = "cloud-watch-logs"
  flow_log_traffic_type = "REJECT"
  flow_log_cloudwatch_log_group_retention_in_days = 3
  flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc-flow-log/"
  flow_log_cloudwatch_log_group_name_suffix = "walt-vpc-logs"
  create_flow_log_cloudwatch_iam_role = true 
}