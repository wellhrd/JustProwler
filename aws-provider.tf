# This is the free TIER You only pay as uou exceede these resources bro 

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.89.0"
      # version = ">= 3.63.0"
    }
  }
}

# Lets settle in N. Virginia
provider "aws" {
  region = "us-east-1"

  access_key = "AKIAYQNJTAUSZ5JHCR4U"
  secret_key = "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"
}