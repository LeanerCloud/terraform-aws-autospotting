terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

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
  function_name = "autospotting-lambda-${module.label.id}"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.autospotting.repository_url}:${var.lambda_source_image_tag}"
  role          = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : aws_iam_role.autospotting_role[0].arn
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  tags          = merge(var.lambda_tags, module.label.tags)

  environment {
    variables = {
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
    }
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
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/autospotting*"]
  }
}

resource "aws_iam_role_policy" "autospotting_policy_lambda" {
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "policy_for_lambda_${module.label.id}"
  role   = aws_iam_role.autospotting_role[count.index].id
  policy = data.aws_iam_policy_document.autospotting_policy[count.index].json
}

resource "aws_iam_role_policy" "autospotting_policy_fargate" {
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "policy_for_fargate_${module.label.id}"
  role   = aws_iam_role.autospotting_task_execution[0].id
  policy = data.aws_iam_policy_document.autospotting_policy[count.index].json
}

resource "aws_sqs_queue" "autospotting_fifo_queue" {
  name                        = var.sqs_fifo_queue_name
  content_based_deduplication = true
  fifo_queue                  = true
  message_retention_seconds   = 900
  visibility_timeout_seconds  = 900
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

resource "aws_sns_topic" "email_notification" {
  name = "email_notifications_${module.label.id}"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.notify_email_addresses)

  topic_arn = aws_sns_topic.email_notification.arn
  protocol  = "email"
  endpoint  = each.value
}

