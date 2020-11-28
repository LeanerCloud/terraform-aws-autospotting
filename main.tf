module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.21.0"
  context = module.this
}

data "aws_regions" "current" {
  all_regions = true
}

locals {
  all_regions         = data.aws_regions.current.names
  unsupported_regions = ["ap-northeast-3"] # These regions currently throw an error when attempting to use them. This is also set in modules/regional/generate_regional_code.tf

  all_usable_regions = setsubtract(local.all_regions, local.unsupported_regions)
  regions            = var.autospotting_regions_enabled == [] ? local.all_usable_regions : var.autospotting_regions_enabled
}

output "regions" {
  value = local.regions
}

module "aws_lambda_function" {
  source = "./modules/lambda"

  label_context = module.label.context

  lambda_zipname           = var.lambda_zipname
  lambda_s3_bucket         = var.lambda_s3_bucket
  lambda_s3_key            = var.lambda_s3_key
  lambda_manage_asg_s3_key = var.lambda_manage_asg_s3_key
  lambda_runtime           = var.lambda_runtime
  lambda_timeout           = var.lambda_timeout
  lambda_memory_size       = var.lambda_memory_size
  lambda_tags              = var.lambda_tags

  autospotting_allowed_instance_types          = var.autospotting_allowed_instance_types
  autospotting_bidding_policy                  = var.autospotting_bidding_policy
  autospotting_cron_schedule                   = var.autospotting_cron_schedule
  autospotting_cron_schedule_state             = var.autospotting_cron_schedule_state
  autospotting_cron_timezone                   = var.autospotting_cron_timezone
  autospotting_disallowed_instance_types       = var.autospotting_disallowed_instance_types
  autospotting_instance_termination_method     = var.autospotting_instance_termination_method
  autospotting_license                         = var.autospotting_license
  autospotting_min_on_demand_number            = var.autospotting_min_on_demand_number
  autospotting_min_on_demand_percentage        = var.autospotting_min_on_demand_percentage
  autospotting_on_demand_price_multiplier      = var.autospotting_on_demand_price_multiplier
  autospotting_patch_beanswalk_userdata        = var.autospotting_patch_beanswalk_userdata
  autospotting_regions_enabled                 = var.autospotting_regions_enabled
  autospotting_spot_price_buffer_percentage    = var.autospotting_spot_price_buffer_percentage
  autospotting_spot_product_description        = var.autospotting_spot_product_description
  autospotting_spot_product_premium            = var.autospotting_spot_product_premium
  autospotting_tag_filtering_mode              = var.autospotting_tag_filtering_mode
  autospotting_tag_filters                     = var.autospotting_tag_filters
  autospotting_termination_notification_action = var.autospotting_termination_notification_action
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
