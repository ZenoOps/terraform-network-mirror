terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.15.0"
    }
  }
}

locals {
  aws_region = "ap-southeast-2"  # Change to your preferred region if needed
}
provider "aws" {
  region = local.aws_region
  shared_credentials_files = ["/home/zeno/.aws/credentials"] # replace with your own PATH
}
