terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }

  }
  backend "s3" {
    bucket = "-terraform-backend-bucket-123"
    key    = "s3-backend"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

