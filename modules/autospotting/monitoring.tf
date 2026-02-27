# ──── CloudWatch Alarms ────

# Lambda alarms are conditional on enable_cost_dashboard (matches CFN)
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_description   = "Lambda function error rate exceeded threshold"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  dimensions = {
    FunctionName = aws_lambda_function.autospotting.function_name
  }

  tags = module.label.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Lambda function is being throttled"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  dimensions = {
    FunctionName = aws_lambda_function.autospotting.function_name
  }

  tags = module.label.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 10000
  treat_missing_data  = "notBreaching"
  alarm_description   = "Lambda function duration approaching timeout"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  dimensions = {
    FunctionName = aws_lambda_function.autospotting.function_name
  }

  tags = module.label.tags
}

# SQS and DynamoDB alarms are unconditional (matches CFN)
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${module.label.id}-sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "SQS queue depth exceeded threshold"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  dimensions = {
    QueueName = aws_sqs_queue.autospotting_fifo_queue.name
  }

  tags = module.label.tags
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_messages" {
  alarm_name          = "${module.label.id}-sqs-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Messages in dead letter queue indicate processing failures"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  dimensions = {
    QueueName = aws_sqs_queue.autospotting_dlq.name
  }

  tags = module.label.tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  alarm_name          = "${module.label.id}-dynamodb-throttles"
  alarm_description   = "Alerts when DynamoDB requests have errors"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  dimensions = {
    TableName = aws_dynamodb_table.customer_accounts.name
  }

  tags = module.label.tags
}
