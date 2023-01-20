provider "aws" {
   region = "eu-central-1"
   version = "v2.70.0"
}

terraform {
  required_version = ">= 0.11.14"

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

resource "aws_dynamodb_table" "main-data-table" {
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  range_key        = "SK"
  name             = "main-data-table"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}
