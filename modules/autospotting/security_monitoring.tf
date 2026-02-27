# ──── Security Monitoring (conditional on enable_cost_dashboard) ────

resource "aws_cloudwatch_log_metric_filter" "failed_login" {
  count          = var.enable_cost_dashboard ? 1 : 0
  name           = "${module.label.id}-failed-login"
  log_group_name = "/aws/lambda/${aws_lambda_function.autospotting.function_name}"
  pattern        = "\"[AUDIT] Login FAILED\""

  metric_transformation {
    name      = "FailedLoginAttempts"
    namespace = "${module.label.id}/Security"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_login" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-excessive-failed-logins"
  alarm_description   = "Alerts when there are more than 10 failed login attempts in 5 minutes (potential brute force attack)"
  metric_name         = "FailedLoginAttempts"
  namespace           = "${module.label.id}/Security"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  tags = module.label.tags
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_access" {
  count          = var.enable_cost_dashboard ? 1 : 0
  name           = "${module.label.id}-unauthorized-access"
  log_group_name = "/aws/lambda/${aws_lambda_function.autospotting.function_name}"
  pattern        = "\"forbidden\" \"Admin access required\""

  metric_transformation {
    name      = "UnauthorizedAccessAttempts"
    namespace = "${module.label.id}/Security"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_access" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-unauthorized-access"
  alarm_description   = "Alerts when there are multiple unauthorized access attempts (privilege escalation attempt)"
  metric_name         = "UnauthorizedAccessAttempts"
  namespace           = "${module.label.id}/Security"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  tags = module.label.tags
}

resource "aws_cloudwatch_log_metric_filter" "rate_limit" {
  count          = var.enable_cost_dashboard ? 1 : 0
  name           = "${module.label.id}-rate-limit"
  log_group_name = "/aws/lambda/${aws_lambda_function.autospotting.function_name}"
  pattern        = "\"rate_limited\" \"Too many requests\""

  metric_transformation {
    name      = "RateLimitedRequests"
    namespace = "${module.label.id}/Security"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "rate_limit" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-excessive-rate-limiting"
  alarm_description   = "Alerts when many requests are being rate limited (potential DoS attack)"
  metric_name         = "RateLimitedRequests"
  namespace           = "${module.label.id}/Security"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  tags = module.label.tags
}

resource "aws_cloudwatch_log_metric_filter" "admin_action" {
  count          = var.enable_cost_dashboard ? 1 : 0
  name           = "${module.label.id}-admin-action"
  log_group_name = "/aws/lambda/${aws_lambda_function.autospotting.function_name}"
  pattern        = "\"[AUDIT]\" \"admin=\""

  metric_transformation {
    name      = "AdminActions"
    namespace = "${module.label.id}/Security"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "cors_block" {
  count          = var.enable_cost_dashboard ? 1 : 0
  name           = "${module.label.id}-cors-block"
  log_group_name = "/aws/lambda/${aws_lambda_function.autospotting.function_name}"
  pattern        = "\"[SECURITY] CORS\""

  metric_transformation {
    name      = "CORSBlockedRequests"
    namespace = "${module.label.id}/Security"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "cors_block" {
  count               = var.enable_cost_dashboard ? 1 : 0
  alarm_name          = "${module.label.id}-cors-blocked"
  alarm_description   = "Alerts when CORS is blocking requests (misconfiguration or attack)"
  metric_name         = "CORSBlockedRequests"
  namespace           = "${module.label.id}/Security"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.email_notification.arn]

  tags = module.label.tags
}
