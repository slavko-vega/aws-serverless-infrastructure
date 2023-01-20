provider "aws" {
   region = "eu-central-1"
}

terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.19"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }

  # backend "local" {
  #   path = "state/terraform.tfstate"
  # }

  backend "s3" {
    encrypt = true
    bucket = "sfcode021-terraform-state"
    dynamodb_table = "terraform-state-lock-dynamo"
    key = "sfcode021/serverless/state/infra-terraform.state"
    region = "eu-central-1"
  }
}

