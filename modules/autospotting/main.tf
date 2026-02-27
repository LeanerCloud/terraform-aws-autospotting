module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  context = var.label_context
}

data "aws_caller_identity" "current" {}

data "aws_arn" "role_arn" {
  count = var.use_existing_iam_role ? 1 : 0
  arn   = var.existing_iam_role_arn
}

data "aws_arn" "lambda_function_arn" {
  arn = aws_lambda_function.autospotting.arn
}

resource "aws_lambda_function" "autospotting" {
  function_name                  = "autospotting-lambda-${module.label.id}"
  package_type                   = "Image"
  image_uri                      = "${aws_ecr_repository.autospotting.repository_url}:${var.lambda_source_image_tag}"
  role                           = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : aws_iam_role.autospotting_role[0].arn
  timeout                        = var.lambda_timeout
  memory_size                    = var.lambda_memory_size
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions
  tags                           = merge(var.lambda_tags, module.label.tags)

  dynamic "tracing_config" {
    for_each = var.lambda_enable_xray ? [1] : []
    content {
      mode = "Active"
    }
  }

  environment {
    variables = merge(
      {
        # Core configuration
        ALLOW_PARALLEL_INSTANCE_REPLACEMENTS     = var.autospotting_allow_parallel_instance_replacements
        ALLOWED_INSTANCE_TYPES                   = var.autospotting_allowed_instance_types
        AUTOMATED_INSTANCE_DATA_UPDATE           = var.autospotting_automated_instance_data_update
        BIDDING_POLICY                           = var.autospotting_bidding_policy
        CONSIDER_EBS_BANDWIDTH                   = var.autospotting_consider_ebs_bandwidth
        CRON_SCHEDULE                            = var.autospotting_cron_schedule
        CRON_SCHEDULE_STATE                      = var.autospotting_cron_schedule_state
        CRON_TIMEZONE                            = var.autospotting_cron_timezone
        DISALLOWED_INSTANCE_TYPES                = var.autospotting_disallowed_instance_types
        ENABLE_INSTANCE_REBALANCE_RECOMMENDATION = var.autospotting_enable_instance_rebalance_recommendation
        HANDLE_LIFECYCLE_HOOK_EVENTS             = var.autospotting_handle_lifecycle_hook_events
        INSTANCE_TYPES_PER_AZ                    = var.autospotting_instance_types_per_az
        MIN_ON_DEMAND_NUMBER                     = var.autospotting_min_on_demand_number
        MIN_ON_DEMAND_PERCENTAGE                 = var.autospotting_min_on_demand_percentage
        NOTIFICATION_SNS_TOPIC                   = aws_sns_topic.email_notification.arn
        ON_DEMAND_PRICE_MULTIPLIER               = var.autospotting_on_demand_price_multiplier
        PRIORITIZED_INSTANCE_TYPES_BIAS          = var.autospotting_prioritized_instance_types_bias
        REGIONS                                  = join(",", var.autospotting_regions_enabled)
        SPOT_ALLOCATION_STRATEGY                 = var.autospotting_spot_allocation_strategy
        SPOT_PRICE_BUFFER_PERCENTAGE             = var.autospotting_spot_price_buffer_percentage
        SQS_QUEUE_URL                            = aws_sqs_queue.autospotting_fifo_queue.id
        TAG_FILTERING_MODE                       = var.autospotting_tag_filtering_mode
        TAG_FILTERS                              = var.autospotting_tag_filters
        TERMINATION_NOTIFICATION_ACTION          = var.autospotting_termination_notification_action

        # Multi-account
        ALLOWED_CUSTOMER_ACCOUNTS    = var.allowed_customer_accounts
        CUSTOMER_EXECUTION_ROLE_NAME = var.customer_execution_role_name
        PRE_APPROVED_COMPANIES       = var.pre_approved_companies
        MAIN_ACCOUNT_ID              = data.aws_caller_identity.current.account_id
        SAAS_MODE                    = var.saas_mode

        # Core tables (always created, matching CFN)
        CUSTOMER_ACCOUNTS_TABLE = aws_dynamodb_table.customer_accounts.name
        COMPANIES_TABLE         = aws_dynamodb_table.companies.name
        BLOCKED_ACCOUNTS_TABLE  = aws_dynamodb_table.blocked_accounts.name
        RATE_LIMIT_TABLE        = aws_dynamodb_table.rate_limit.name
        LOCKING_TABLE           = aws_dynamodb_table.locking.name
        DEFERRED_ACTIONS_TABLE  = aws_dynamodb_table.deferred_actions.name

        # RISP Coverage
        ENABLE_RISP_COVERAGE          = var.enable_risp_coverage
        RISP_BILLING_ACCOUNT_ROLE_ARN = var.risp_billing_account_role_arn
        RISP_COVERAGE_THRESHOLD       = var.risp_coverage_threshold
      },

      # Cost dashboard references (conditional)
      var.enable_cost_dashboard ? {
        ENABLE_COST_API                   = "true"
        DASHBOARD_API_KEY_SECRET_ARN      = aws_secretsmanager_secret.dashboard_api_key[0].arn
        TOKEN_HASHING_SECRET_ARN          = aws_secretsmanager_secret.token_hashing[0].arn
        COST_DYNAMODB_TABLE               = aws_dynamodb_table.cost_snapshots[0].name
        COST_HISTORY_BUCKET               = aws_s3_bucket.cost_history[0].id
        ATHENA_DATABASE                   = aws_glue_catalog_database.cost_data[0].name
        ATHENA_WORKGROUP                  = aws_athena_workgroup.cost_analytics[0].name
        GLOBAL_CONFIG_TABLE               = aws_dynamodb_table.global_config[0].name
        USERS_TABLE                       = aws_dynamodb_table.users[0].name
        COMPANY_MEMBERSHIPS_TABLE         = aws_dynamodb_table.company_memberships[0].name
        INVITATIONS_TABLE                 = aws_dynamodb_table.invitations[0].name
        INVOICES_TABLE                    = aws_dynamodb_table.invoices[0].name
        COMPANY_SETTINGS_TABLE            = aws_dynamodb_table.company_settings[0].name
        ACCOUNT_SETTINGS_TABLE            = aws_dynamodb_table.account_settings[0].name
        SES_FROM_ADDRESS                  = var.ses_from_address
        SES_CONFIGURATION_SET             = aws_ses_configuration_set.transactional[0].name
        ADMIN_EMAIL                       = var.admin_email
        STRIPE_API_KEY_SECRET_ARN         = aws_secretsmanager_secret.stripe_api_key[0].arn
        STRIPE_PUBLISHABLE_KEY_SECRET_ARN = aws_secretsmanager_secret.stripe_publishable_key[0].arn
        STRIPE_WEBHOOK_SECRET_ARN         = aws_secretsmanager_secret.stripe_webhook_secret[0].arn
        STRIPE_PRICE_ID_SECRET_ARN        = aws_secretsmanager_secret.stripe_price_id[0].arn
        DASHBOARD_URL                     = var.dashboard_domain_name != "" ? "https://${var.dashboard_domain_name}" : ""
      } : {},

      # RISP coverage table reference (conditional)
      var.enable_risp_coverage ? {
        RISP_COVERAGE_TABLE = aws_dynamodb_table.risp_coverage[0].name
      } : {},
    )
  }
  depends_on = [
    docker_registry_image.destination,
  ]
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "ecs-tasks.amazonaws.com",
      ]

    }
  }
}

resource "aws_iam_role" "autospotting_role" {
  count                 = var.use_existing_iam_role ? 0 : 1
  name                  = "autospotting-role-${module.label.id}"
  path                  = "/lambda/"
  assume_role_policy    = data.aws_iam_policy_document.lambda_policy.json
  force_detach_policies = true
  permissions_boundary  = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null
}

data "aws_iam_policy_document" "autospotting_policy" {
  count = var.use_existing_iam_role ? 0 : 1
  statement {
    actions = [
      "autoscaling:AttachInstances",
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "autoscaling:DetachInstances",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetInstanceProtection",
      "autoscaling:SuspendProcesses",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "aws-marketplace:MeterUsage",
      "aws-marketplace:RegisterUsage",
      "cloudformation:Describe*",
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:ListApplications",
      "codedeploy:ListDeploymentGroups",
      "elasticbeanstalk:DescribeEnvironments",
      "ec2:AssociateAddress",
      "ec2:AttachVolume",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteTags",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstances",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:DisassociateAddress",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ecs:DeregisterContainerInstance",
      "ecs:DescribeContainerInstances",
      "ecs:ListClusters",
      "ecs:ListContainerInstances",
      "ecs:UpdateContainerInstancesState",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "iam:CreateServiceLinkedRole",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "sns:Publish",
    ]

    resources = ["*"]
  }
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.autospotting_fifo_queue.arn]
  }
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:GetParameterHistory"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/autospotting*"]
  }
}

resource "aws_iam_role_policy" "autospotting_policy_lambda" {
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "policy_for_lambda_${module.label.id}"
  role   = aws_iam_role.autospotting_role[count.index].id
  policy = data.aws_iam_policy_document.autospotting_policy[count.index].json
}

resource "aws_iam_role_policy" "autospotting_policy_fargate" {
  count  = var.use_existing_iam_role || !var.deploy_fargate ? 0 : 1
  name   = "policy_for_fargate_${module.label.id}"
  role   = aws_iam_role.autospotting_task_execution[0].id
  policy = data.aws_iam_policy_document.autospotting_policy[0].json
}

# Service-linked roles
resource "aws_iam_service_linked_role" "spot" {
  count            = var.create_service_linked_roles ? 1 : 0
  aws_service_name = "spot.amazonaws.com"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_sqs_queue" "autospotting_fifo_queue" {
  name                        = var.sqs_fifo_queue_name
  content_based_deduplication = true
  fifo_queue                  = true
  message_retention_seconds   = 900
  visibility_timeout_seconds  = 900
  sqs_managed_sse_enabled     = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.autospotting_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "autospotting_dlq" {
  name                      = "${module.label.id}-dlq.fifo"
  fifo_queue                = true
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_lambda_event_source_mapping" "autospotting_lambda_event_source_mapping_new_role" {
  count            = var.use_existing_iam_role ? 0 : 1
  event_source_arn = aws_sqs_queue.autospotting_fifo_queue.arn
  function_name    = aws_lambda_function.autospotting.arn
  batch_size       = 1
  depends_on       = [aws_iam_role_policy.autospotting_policy_lambda]
}

resource "aws_lambda_event_source_mapping" "autospotting_lambda_event_source_mapping_existing_role" {
  count            = var.use_existing_iam_role ? 1 : 0
  event_source_arn = aws_sqs_queue.autospotting_fifo_queue.arn
  batch_size       = 1
  function_name    = aws_lambda_function.autospotting.arn
}

# DeferredActions DynamoDB Streams event source mapping
# Processes TTL-expired items (REMOVE events from DynamoDB service) for deferred spot replacements
resource "aws_lambda_event_source_mapping" "deferred_actions_stream" {
  count             = var.use_existing_iam_role ? 0 : 1
  event_source_arn  = aws_dynamodb_table.deferred_actions.stream_arn
  function_name     = aws_lambda_function.autospotting.arn
  starting_position = "LATEST"
  batch_size        = 1

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["REMOVE"]
        userIdentity = {
          type        = ["Service"]
          principalId = ["dynamodb.amazonaws.com"]
        }
      })
    }
  }

  depends_on = [aws_iam_role_policy.autospotting_policy_lambda]
}

resource "aws_lambda_event_source_mapping" "deferred_actions_stream_existing_role" {
  count             = var.use_existing_iam_role ? 1 : 0
  event_source_arn  = aws_dynamodb_table.deferred_actions.stream_arn
  function_name     = aws_lambda_function.autospotting.arn
  starting_position = "LATEST"
  batch_size        = 1

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["REMOVE"]
        userIdentity = {
          type        = ["Service"]
          principalId = ["dynamodb.amazonaws.com"]
        }
      })
    }
  }
}

resource "aws_sns_topic" "email_notification" {
  name = "email_notifications_${module.label.id}"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.notify_email_addresses)

  topic_arn = aws_sns_topic.email_notification.arn
  protocol  = "email"
  endpoint  = each.value
}

