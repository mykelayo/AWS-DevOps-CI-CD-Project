# 1: DEFINE AWS VERSION
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6"
    }
  }
}
# 2: DEFINE THE REGION (N. Virginia)
provider "aws" {
  region = "us-east-1"
}