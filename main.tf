module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  context = module.this
  enabled = true
}

data "aws_regions" "current" {}

locals {
  all_regions = data.aws_regions.current.names
  regions     = var.autospotting_regions_enabled == [] ? local.all_regions : var.autospotting_regions_enabled
}

output "regions" {
  value = local.regions
}

module "aws_lambda_function" {
  source = "./modules/lambda"

  label_context = module.label.context

  lambda_cpu_architecture = var.lambda_cpu_architecture
  lambda_source_ecr       = var.lambda_source_ecr
  lambda_source_image     = var.lambda_source_image
  lambda_source_image_tag = var.lambda_source_image_tag
  lambda_timeout          = var.lambda_timeout
  lambda_memory_size      = var.lambda_memory_size
  lambda_tags             = var.lambda_tags

  sqs_fifo_queue_name    = "${module.label.id}.fifo"
  notify_email_addresses = var.notify_email_addresses

  autospotting_allow_parallel_instance_replacements = var.autospotting_allow_parallel_instance_replacements
  autospotting_allowed_instance_types               = var.autospotting_allowed_instance_types
  autospotting_automated_instance_data_update       = var.autospotting_automated_instance_data_update
  autospotting_bidding_policy                       = var.autospotting_bidding_policy
  autospotting_consider_ebs_bandwidth               = var.autospotting_consider_ebs_bandwidth
  autospotting_cron_schedule                        = var.autospotting_cron_schedule
  autospotting_cron_schedule_state                  = var.autospotting_cron_schedule_state
  autospotting_cron_timezone                        = var.autospotting_cron_timezone
  autospotting_disallowed_instance_types            = var.autospotting_disallowed_instance_types
  autospotting_ebs_gp2_conversion_threshold         = var.autospotting_ebs_gp2_conversion_threshold

  autospotting_enable_instance_rebalance_recommendation = var.autospotting_enable_instance_rebalance_recommendation
  autospotting_instance_termination_method              = var.autospotting_instance_termination_method
  autospotting_min_on_demand_number                     = var.autospotting_min_on_demand_number
  autospotting_min_on_demand_percentage                 = var.autospotting_min_on_demand_percentage
  autospotting_on_demand_price_multiplier               = var.autospotting_on_demand_price_multiplier
  autospotting_patch_beanswalk_userdata                 = var.autospotting_patch_beanswalk_userdata
  autospotting_prioritized_instance_types_bias          = var.autospotting_prioritized_instance_types_bias
  autospotting_regions_enabled                          = var.autospotting_regions_enabled
  autospotting_savings_reports_frequency                = var.autospotting_savings_reports_frequency
  autospotting_spot_allocation_strategy                 = var.autospotting_spot_allocation_strategy
  autospotting_spot_price_buffer_percentage             = var.autospotting_spot_price_buffer_percentage
  autospotting_spot_product_description                 = var.autospotting_spot_product_description
  autospotting_spot_product_premium                     = var.autospotting_spot_product_premium
  autospotting_tag_filtering_mode                       = var.autospotting_tag_filtering_mode
  autospotting_tag_filters                              = var.autospotting_tag_filters
  autospotting_termination_notification_action          = var.autospotting_termination_notification_action
}

# Regional resources that trigger the main Lambda function
module "regional" {
  source                  = "./modules/regional"
  autospotting_lambda_arn = module.aws_lambda_function.arn
  label_context           = module.label.context
  regions                 = local.regions
}

resource "aws_lambda_permission" "cloudwatch_events_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_frequency.arn
}

resource "aws_cloudwatch_event_target" "cloudwatch_target" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_frequency.name
  target_id = "run_autospotting"
  arn       = module.aws_lambda_function.arn
}

resource "aws_cloudwatch_event_rule" "cloudwatch_frequency" {
  name                = "${module.label.id}_frequency"
  schedule_expression = var.lambda_run_frequency
}

resource "aws_cloudwatch_log_group" "log_group_autospotting" {
  name              = "/aws/lambda/${module.label.id}"
  retention_in_days = 7
}

# Elastic Beanstalk policy

data "aws_iam_policy_document" "beanstalk" {
  statement {
    actions = [
      "cloudformation:DescribeStackResource",
      "cloudformation:DescribeStackResources",
      "cloudformation:SignalResource",
      "cloudformation:RegisterListener",
      "cloudformation:GetListenerCredentials"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "beanstalk_policy" {
  name   = "elastic_beanstalk_iam_policy_for_${module.label.id}"
  policy = data.aws_iam_policy_document.beanstalk.json
}
