# ──── Scheduled Events ────

# Cost collection: hourly (conditional on enable_cost_dashboard)
resource "aws_cloudwatch_event_rule" "cost_collection" {
  count               = var.enable_cost_dashboard ? 1 : 0
  name                = "${module.label.id}-cost-collection"
  description         = "Hourly cost data collection"
  schedule_expression = "rate(1 hour)"

  tags = module.label.tags
}

resource "aws_cloudwatch_event_target" "cost_collection" {
  count     = var.enable_cost_dashboard ? 1 : 0
  rule      = aws_cloudwatch_event_rule.cost_collection[0].name
  target_id = "cost-collection"
  arn       = aws_sqs_queue.autospotting_fifo_queue.arn

  input = jsonencode({
    action = "collect_costs"
  })

  sqs_target {
    message_group_id = "autospotting_cost_collection"
  }
}

# RISP coverage collection: weekly Sunday 6AM UTC (conditional on enable_risp_coverage)
resource "aws_cloudwatch_event_rule" "risp_collection" {
  count               = var.enable_risp_coverage ? 1 : 0
  name                = "${module.label.id}-risp-collection"
  description         = "Weekly RI/SP coverage data collection"
  schedule_expression = "cron(0 6 ? * SUN *)"

  tags = module.label.tags
}

resource "aws_cloudwatch_event_target" "risp_collection" {
  count     = var.enable_risp_coverage ? 1 : 0
  rule      = aws_cloudwatch_event_rule.risp_collection[0].name
  target_id = "risp-collection"
  arn       = aws_sqs_queue.autospotting_fifo_queue.arn

  input = jsonencode({
    action = "collect_risp_coverage"
  })

  sqs_target {
    message_group_id = "autospotting_risp_collection"
  }
}

# Invoice generation: monthly 1st at 9AM UTC (conditional on enable_cost_dashboard)
resource "aws_cloudwatch_event_rule" "invoice_generation" {
  count               = var.enable_cost_dashboard ? 1 : 0
  name                = "${module.label.id}-invoice-generation"
  description         = "Monthly invoice generation"
  schedule_expression = "cron(0 9 1 * ? *)"

  tags = module.label.tags
}

resource "aws_cloudwatch_event_target" "invoice_generation" {
  count     = var.enable_cost_dashboard ? 1 : 0
  rule      = aws_cloudwatch_event_rule.invoice_generation[0].name
  target_id = "invoice-generation"
  arn       = aws_sqs_queue.autospotting_fifo_queue.arn

  input = jsonencode({
    action = "generate_invoices"
  })

  sqs_target {
    message_group_id = "autospotting_invoice_generation"
  }
}

# Trial expiration check: daily 6AM UTC (conditional on saas_mode)
resource "aws_cloudwatch_event_rule" "trial_expiration" {
  count               = var.saas_mode ? 1 : 0
  name                = "${module.label.id}-trial-expiration"
  description         = "Daily trial expiration check"
  schedule_expression = "cron(0 6 * * ? *)"

  tags = module.label.tags
}

resource "aws_cloudwatch_event_target" "trial_expiration" {
  count     = var.saas_mode ? 1 : 0
  rule      = aws_cloudwatch_event_rule.trial_expiration[0].name
  target_id = "trial-expiration"
  arn       = aws_sqs_queue.autospotting_fifo_queue.arn

  input = jsonencode({
    action = "check_trial_expirations"
  })

  sqs_target {
    message_group_id = "autospotting_trial_expiration"
  }
}

# SQS queue policy additions for scheduled events
resource "aws_sqs_queue_policy" "scheduled_events" {
  count     = var.enable_cost_dashboard || var.enable_risp_coverage || var.saas_mode ? 1 : 0
  queue_url = aws_sqs_queue.autospotting_fifo_queue.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScheduledEventsToSendSQS"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.autospotting_fifo_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = compact([
              var.enable_cost_dashboard ? aws_cloudwatch_event_rule.cost_collection[0].arn : "",
              var.enable_risp_coverage ? aws_cloudwatch_event_rule.risp_collection[0].arn : "",
              var.enable_cost_dashboard ? aws_cloudwatch_event_rule.invoice_generation[0].arn : "",
              var.saas_mode ? aws_cloudwatch_event_rule.trial_expiration[0].arn : "",
            ])
          }
        }
      }
    ]
  })
}
