terraform {
  backend "s3" {
    encrypt = true
  }

  required_version = "~> 1.1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}
