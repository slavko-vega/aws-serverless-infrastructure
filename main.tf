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

resource "aws_lambda_function" "people_service" {
  function_name = "PeopleService"
  role = aws_iam_role.lambda_role.arn
  handler = "index.handler"
  runtime = "nodejs16.x"
  s3_bucket = "arn:aws:s3:::sfcode021-hello-world-artifacts"
  s3_key = "build.zip"
  environment {
    variables = {
      "DYNAMODB_TABLE" = "main-data-table"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_people_service"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy_people_service"
  role = aws_iam_role.lambda_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/main-data-table"
        }
    ]
}
EOF
}