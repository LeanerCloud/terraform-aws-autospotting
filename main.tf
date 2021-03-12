module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.13.0"
  context     = var.label_context
  namespace   = var.label_namespace
  environment = var.label_environment
  stage       = var.label_stage
  name        = var.label_name
  attributes  = var.label_attributes
  tags        = var.label_tags
  delimiter   = var.label_delimiter
}

resource "aws_lambda_function" "autospotting" {
  count            = var.autospotting_enabled ? 1 : 0
  function_name    = module.label.id
  filename         = var.lambda_zipname
  source_code_hash = var.lambda_zipname == null ? null : filebase64sha256(var.lambda_zipname)
  s3_bucket        = var.lambda_zipname == null ? var.lambda_s3_bucket : null
  s3_key           = var.lambda_zipname == null ? var.lambda_s3_key : null
  role             = join("", aws_iam_role.autospotting_role[*].arn)
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  handler          = "AutoSpotting"
  memory_size      = var.lambda_memory_size
  tags             = merge(var.lambda_tags, module.label.tags)

  environment {
    variables = {
      ALLOWED_INSTANCE_TYPES       = var.autospotting_allowed_instance_types
      DISALLOWED_INSTANCE_TYPES    = var.autospotting_disallowed_instance_types
      INSTANCE_TERMINATION_METHOD  = var.autospotting_instance_termination_method
      MIN_ON_DEMAND_NUMBER         = var.autospotting_min_on_demand_number
      MIN_ON_DEMAND_PERCENTAGE     = var.autospotting_min_on_demand_percentage
      ON_DEMAND_PRICE_MULTIPLIER   = var.autospotting_on_demand_price_multiplier
      SPOT_PRICE_BUFFER_PERCENTAGE = var.autospotting_spot_price_buffer_percentage
      SPOT_PRODUCT_DESCRIPTION     = var.autospotting_spot_product_description
      BIDDING_POLICY               = var.autospotting_bidding_policy
      REGIONS                      = var.autospotting_regions_enabled
      TAG_FILTERS                  = var.autospotting_tag_filters
      TAG_FILTERING_MODE           = var.autospotting_tag_filtering_mode
      LICENSE                      = var.autospotting_license
    }
  }
}

module "aws_lambda_function" {
  source = "./modules/lambda"

  label_context = module.label.context

  lambda_zipname     = var.lambda_zipname
  lambda_s3_bucket   = var.lambda_s3_bucket
  lambda_s3_key      = var.lambda_s3_key
  lambda_role_arn    = join("", aws_iam_role.autospotting_role[*].arn)
  lambda_runtime     = var.lambda_runtime
  lambda_timeout     = var.lambda_timeout
  lambda_memory_size = var.lambda_memory_size
  lambda_tags        = var.lambda_tags

  autospotting_enabled                      = var.autospotting_enabled
  autospotting_allowed_instance_types       = var.autospotting_allowed_instance_types
  autospotting_disallowed_instance_types    = var.autospotting_disallowed_instance_types
  autospotting_instance_termination_method  = var.autospotting_instance_termination_method
  autospotting_min_on_demand_number         = var.autospotting_min_on_demand_number
  autospotting_min_on_demand_percentage     = var.autospotting_min_on_demand_percentage
  autospotting_on_demand_price_multiplier   = var.autospotting_on_demand_price_multiplier
  autospotting_spot_price_buffer_percentage = var.autospotting_spot_price_buffer_percentage
  autospotting_spot_product_description     = var.autospotting_spot_product_description
  autospotting_bidding_policy               = var.autospotting_bidding_policy
  autospotting_regions_enabled              = var.autospotting_regions_enabled
  autospotting_tag_filters                  = var.autospotting_tag_filters
  autospotting_tag_filtering_mode           = var.autospotting_tag_filtering_mode
  autospotting_license                      = var.autospotting_license
}

resource "aws_iam_role" "autospotting_role" {
  count                 = var.autospotting_enabled ? 1 : 0
  name                  = module.label.id
  path                  = "/lambda/"
  assume_role_policy    = file("${path.module}/lambda-policy.json")
  force_detach_policies = true
}

resource "aws_iam_role_policy" "autospotting_policy" {
  count  = var.autospotting_enabled ? 1 : 0
  name   = "policy_for_${module.label.id}"
  role   = join("", aws_iam_role.autospotting_role[*].id)
  policy = file("${path.module}/autospotting-policy.json")
}

resource "aws_lambda_permission" "cloudwatch_events_permission" {
  count         = var.autospotting_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = join("", aws_lambda_function.autospotting[*].function_name)
  principal     = "events.amazonaws.com"
  source_arn    = join("", aws_cloudwatch_event_rule.cloudwatch_frequency[*].arn)
}

resource "aws_cloudwatch_event_target" "cloudwatch_target" {
  count     = var.autospotting_enabled ? 1 : 0
  rule      = join("", aws_cloudwatch_event_rule.cloudwatch_frequency[*].name)
  target_id = "run_autospotting"
  arn       = join("", aws_lambda_function.autospotting[*].arn)
}

resource "aws_cloudwatch_event_rule" "cloudwatch_frequency" {
  count               = var.autospotting_enabled ? 1 : 0
  name                = "${module.label.id}_frequency"
  schedule_expression = var.lambda_run_frequency
}

resource "aws_cloudwatch_log_group" "log_group_autospotting" {
  /*
  Don't add count here, just in case we disable autospotting on an environment,
  but want to check out the logs later...
  */
  name              = "/aws/lambda/${module.label.id}"
  retention_in_days = 7
}

