provider "aws" {
   region = "eu-central-1"
}

terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
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

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_hello_world_service"
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
  name = "lambda_policy_hello_world_service"
  role = aws_iam_role.lambda_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3SID",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "*"
        },
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

resource "aws_lambda_function" "hello_world_service" {
  function_name = "HelloWorld"
  role = aws_iam_role.lambda_role.arn
  handler = "index.handler"
  runtime = "nodejs16.x"
  s3_bucket = "sfcode021-hello-world-artifacts"
  s3_key = "build.zip"
  environment {
    variables = {
      "DYNAMODB_TABLE" = "main-data-table"
    }
  }
}

#############################################
## API Gateway
#############################################

# resource "aws_apigatewayv2_api" "lambda" {
#   name          = "serverless_lambda_gw"
#   protocol_type = "HTTP"
# }

# resource "aws_apigatewayv2_stage" "lambda" {
#   api_id = aws_apigatewayv2_api.lambda.id

#   name        = "serverless_lambda_stage"
#   auto_deploy = true

#   # access_log_settings {
#   #   destination_arn = aws_cloudwatch_log_group.api_gw.arn

#   #   format = jsonencode({
#   #     requestId               = "$context.requestId"
#   #     sourceIp                = "$context.identity.sourceIp"
#   #     requestTime             = "$context.requestTime"
#   #     protocol                = "$context.protocol"
#   #     httpMethod              = "$context.httpMethod"
#   #     resourcePath            = "$context.resourcePath"
#   #     routeKey                = "$context.routeKey"
#   #     status                  = "$context.status"
#   #     responseLength          = "$context.responseLength"
#   #     integrationErrorMessage = "$context.integrationErrorMessage"
#   #     }
#   #   )
#   # }
# }

# resource "aws_apigatewayv2_integration" "hello_world" {
#   api_id = aws_apigatewayv2_api.lambda.id

#   integration_uri    = aws_lambda_function.hello_world_service.arn
#   integration_type   = "AWS_PROXY"
#   integration_method = "POST"
# }

# resource "aws_apigatewayv2_route" "hello_world" {
#   api_id = aws_apigatewayv2_api.lambda.id

#   route_key = "GET /hello"
#   target    = "integrations/${aws_apigatewayv2_integration.hello_world.id}"
# }

# # resource "aws_cloudwatch_log_group" "api_gw" {
# #   name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

# #   retention_in_days = 30
# # }

# resource "aws_lambda_permission" "api_gw" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.hello_world_service.function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
# }