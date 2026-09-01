
# ==============================================================================
# DynamoDB
# ==============================================================================
resource "aws_dynamodb_table" "events" {
  name         = "terraform-event-driven-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  server_side_encryption {
    enabled = true
  }

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "event-driven-events"
  }
}

# ==============================================================================
# IAM - API Lambda
# ==============================================================================

resource "aws_iam_role" "api_lambda" {
  name = "terraform-event-driven-api-role"

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
    Name    = "event-driven-api-role"
  }
}

resource "aws_iam_role_policy" "api_lambda_dynamodb" {
  name = "terraform-event-driven-api-dynamodb"
  role = aws_iam_role.api_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:PutItem"
        ]

        Resource = aws_dynamodb_table.events.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_lambda_logging" {
  name = "terraform-event-driven-api-logging"
  role = aws_iam_role.api_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}



# ==============================================================================
# IAM - Processor Lambda
# ==============================================================================
resource "aws_iam_role" "processor_lambda" {
  name = "terraform-event-driven-processor-role"

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
    Name    = "event-driven-processor-role"
  }
}

resource "aws_iam_role_policy" "processor_lambda_stream" {
  name = "terraform-event-driven-processor-stream"
  role = aws_iam_role.processor_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]

        Resource = aws_dynamodb_table.events.stream_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "processor_lambda_logging" {
  name = "terraform-event-driven-processor-logging"
  role = aws_iam_role.processor_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "processor_lambda_sns" {
  name = "terraform-event-driven-processor-sns"
  role = aws_iam_role.processor_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}


# ==============================================================================
# Lambda Functions
# ==============================================================================
data "archive_file" "api_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/api"
  output_path = "${path.module}/lambda/api/function.zip"
}

resource "aws_lambda_function" "api" {
  function_name = "terraform-event-driven-api"

  role = aws_iam_role.api_lambda.arn

  filename         = data.archive_file.api_lambda.output_path
  source_code_hash = data.archive_file.api_lambda.output_base64sha256

  handler = "handler.lambda_handler"
  runtime = "python3.13"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.events.name
    }
  }

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "event-driven-api"
  }
}

data "archive_file" "processor_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/processor"
  output_path = "${path.module}/lambda/processor/function.zip"
}

resource "aws_lambda_function" "processor" {
  function_name = "terraform-event-driven-processor"

  role = aws_iam_role.processor_lambda.arn

  filename         = data.archive_file.processor_lambda.output_path
  source_code_hash = data.archive_file.processor_lambda.output_base64sha256

  handler = "handler.lambda_handler"
  runtime = "python3.13"

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.notifications.arn

    }
  }

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "event-driven-processor"
  }
}



# ==============================================================================
# API Gateway
# ==============================================================================
resource "aws_apigatewayv2_api" "api" {
  name          = "terraform-event-driven-api"
  protocol_type = "HTTP"

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "event-driven-api"
  }
}

resource "aws_apigatewayv2_integration" "api_lambda" {
  api_id = aws_apigatewayv2_api.api.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "event" {
  api_id = aws_apigatewayv2_api.api.id

  route_key = "POST /events"

  target = "integrations/${aws_apigatewayv2_integration.api_lambda.id}"
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

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "event-driven-api-default"
  }
}


# ==============================================================================
# DynamoDB Stream Event Source
# ==============================================================================
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = aws_dynamodb_table.events.stream_arn
  function_name     = aws_lambda_function.processor.arn
  starting_position = "LATEST"

  batch_size                         = 10
  maximum_batching_window_in_seconds = 5

  enabled = true
}

# ==============================================================================
# SNS
# ==============================================================================

resource "aws_sns_topic" "notifications" {
  name = "terraform-event-driven-notifications"

  tags = {
    Project = "terraform-aws-portfolio"
    Name    = "event-driven-notifications"
  }
}
