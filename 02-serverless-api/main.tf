resource "aws_dynamodb_table" "contacts" {
  name         = "terraform-serverless-contacts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "serverless-contacts"
  }
}

resource "aws_iam_role" "lambda_execution" {
  name = "terraform-serverless-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "terraform-aws-portfolio"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "api" {
  function_name = "terraform-serverless-api"

  role = aws_iam_role.lambda_execution.arn

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  handler = "handler.lambda_handler"
  runtime = "python3.13"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.contacts.name
    }
  }

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "serverless-api"
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "terraform-serverless-dynamodb-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:PutItem"
        ]

        Resource = aws_dynamodb_table.contacts.arn
      }
    ]
  })
}

resource "aws_apigatewayv2_api" "api" {
  name          = "terraform-serverless-api"
  protocol_type = "HTTP"

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "serverless-api"
  }
}
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.api.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "contact" {
  api_id = aws_apigatewayv2_api.api.id

  route_key = "POST /contact"

  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.api.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.api.id

  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = false
    throttling_burst_limit   = 100
    throttling_rate_limit    = 50
  }

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "serverless-api-default"
  }
}


