module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  context = module.this
  enabled = true
}

data "aws_arn" "role_arn" {
  count = var.use_existing_iam_role ? 1 : 0
  arn   = var.existing_iam_role_arn
}

data "aws_arn" "permissions_boundary" {
  count = var.permissions_boundary_arn != "" ? 1 : 0
  arn   = var.permissions_boundary_arn
}


data "aws_iam_role" "existing" {
  count = var.use_existing_iam_role ? 1 : 0
  name  = split("/", data.aws_arn.role_arn[0].resource)[1]
}

data "aws_subnet" "existing" {
  count = length(var.existing_subnets)
  id    = var.existing_subnets[count.index]
}

data "aws_regions" "current" {

  lifecycle {
    # The list of subnets should not be empty
    /* postcondition {
      condition     = var.use_existing_subnets && length(var.existing_subnets) != 0
      error_message = "The list of subnets should not be empty."
    } */
  }
}

data "aws_cloudwatch_event_bus" "default" {
  name = "default"
}

locals {
  all_regions = data.aws_regions.current.names
  regions     = var.autospotting_regions_enabled == [] ? local.all_regions : var.autospotting_regions_enabled
}

output "regions" {
  value = local.regions
}

module "autospotting" {
  source = "./modules/autospotting"

  label_context = module.label.context

  lambda_cpu_architecture = var.lambda_cpu_architecture
  lambda_source_ecr       = var.lambda_source_ecr
  lambda_source_image     = var.lambda_source_image
  lambda_source_image_tag = var.lambda_source_image_tag
  lambda_timeout          = var.lambda_timeout
  lambda_memory_size      = var.lambda_memory_size
  lambda_tags             = var.lambda_tags
  lambda_use_public_ecr   = var.lambda_use_public_ecr

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

  autospotting_enable_instance_rebalance_recommendation = var.autospotting_enable_instance_rebalance_recommendation
  autospotting_instance_types_per_az                    = var.autospotting_instance_types_per_az
  autospotting_min_on_demand_number                     = var.autospotting_min_on_demand_number
  autospotting_min_on_demand_percentage                 = var.autospotting_min_on_demand_percentage
  autospotting_on_demand_price_multiplier               = var.autospotting_on_demand_price_multiplier
  autospotting_prioritized_instance_types_bias          = var.autospotting_prioritized_instance_types_bias
  autospotting_regions_enabled                          = var.autospotting_regions_enabled
  autospotting_savings_reports_frequency                = var.autospotting_savings_reports_frequency
  autospotting_spot_allocation_strategy                 = var.autospotting_spot_allocation_strategy
  autospotting_spot_price_buffer_percentage             = var.autospotting_spot_price_buffer_percentage
  autospotting_tag_filtering_mode                       = var.autospotting_tag_filtering_mode
  autospotting_tag_filters                              = var.autospotting_tag_filters
  autospotting_termination_notification_action          = var.autospotting_termination_notification_action

  use_existing_iam_role    = var.use_existing_iam_role
  existing_iam_role_arn    = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : ""
  use_existing_subnets     = var.use_existing_subnets
  existing_subnets         = var.existing_subnets
  permissions_boundary_arn = var.permissions_boundary_arn
}

# Regional resources that trigger the main Lambda function
module "regional" {
  source                     = "./modules/regional"
  autospotting_sqs_queue_url = module.autospotting.sqs_queue_url
  autospotting_sqs_queue_arn = module.autospotting.sqs_queue_arn
  label_context              = module.label.context
  regions                    = local.regions
  put_event_role_arn         = var.use_existing_iam_role ? var.existing_iam_role_arn : aws_iam_role.put_events_role[0].arn
}

resource "aws_lambda_permission" "cloudwatch_events_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.autospotting.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_frequency.arn
}

resource "aws_cloudwatch_event_target" "cloudwatch_target" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_frequency.name
  target_id = "run_autospotting"
  arn       = module.autospotting.arn
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
  count = var.use_existing_iam_role ? 0 : 1
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
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "elastic_beanstalk_iam_policy_for_${module.label.id}"
  policy = data.aws_iam_policy_document.beanstalk[0].json
}

resource "aws_iam_role" "put_events_role" {
  count                 = var.use_existing_iam_role ? 0 : 1
  name                  = "autospotting-event-bridge-role-${module.label.id}"
  path                  = "/events/"
  assume_role_policy    = data.aws_iam_policy_document.put_events_assume_policy[0].json
  force_detach_policies = true
  permissions_boundary  = var.permissions_boundary_arn != "" ? data.aws_arn.permissions_boundary[0].arn : null
}

data "aws_iam_policy_document" "put_events_policy" {
  count = var.use_existing_iam_role ? 0 : 1
  statement {
    actions = [
      "events:PutEvents",
    ]
    resources = [data.aws_cloudwatch_event_bus.default.arn]
  }
}

data "aws_iam_policy_document" "put_events_assume_policy" {
  count = var.use_existing_iam_role ? 0 : 1
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy" "put_event_policy_attachment" {
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "policy_for_put_events_${module.label.id}"
  role   = aws_iam_role.put_events_role[count.index].id
  policy = data.aws_iam_policy_document.put_events_policy[count.index].json
}
