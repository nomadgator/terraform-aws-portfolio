output "dynamodb_table_name" {
  description = "Name of the event-driven DynamoDB table"
  value       = aws_dynamodb_table.events.name
}

output "dynamodb_stream_arn" {
  description = "ARN of the DynamoDB Stream"
  value       = aws_dynamodb_table.events.stream_arn
}

output "api_endpoint" {
  description = "API Gateway endpoint for the event-driven API"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS notification topic"
  value       = aws_sns_topic.notifications.arn
}
