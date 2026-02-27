# ──── SES Configuration (conditional on enable_cost_dashboard) ────

resource "aws_ses_configuration_set" "transactional" {
  count = var.enable_cost_dashboard ? 1 : 0
  name  = "${module.label.id}-transactional"
}

resource "aws_ses_event_destination" "bounce_complaint" {
  count                  = var.enable_cost_dashboard ? 1 : 0
  name                   = "${module.label.id}-bounce-complaint-handler"
  configuration_set_name = aws_ses_configuration_set.transactional[0].name
  enabled                = true
  matching_types         = ["bounce", "complaint", "delivery"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_notifications[0].arn
  }
}

resource "aws_sns_topic" "ses_notifications" {
  count             = var.enable_cost_dashboard ? 1 : 0
  name              = "${module.label.id}-ses-notifications"
  kms_master_key_id = var.enable_kms_encryption ? aws_kms_key.sns[0].arn : null

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-SES-Notifications"
  })
}

resource "aws_sns_topic_subscription" "ses_notifications_email" {
  count     = var.enable_cost_dashboard && var.admin_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.ses_notifications[0].arn
  protocol  = "email"
  endpoint  = var.admin_email
}
