terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}

data "aws_arn" "autospotting_sqs_queue_arn" {
  arn = var.autospotting_sqs_queue_arn
}


module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"
  context = var.label_context
}


# Event rule for capturing Spot events: termination and rebalancing
resource "aws_cloudwatch_event_rule" "autospotting_regional_ec2_spot_event_capture" {
  name        = "autospotting_spot_event_capture_${module.label.id}"
  description = "Capture Spot market events that are only fired within AWS regions and need to be forwarded to the central Lambda function"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "EC2 Spot Instance Interruption Warning",
    "EC2 Instance Rebalance Recommendation"
  ],
  "source": [
    "aws.ec2"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "autospotting_regional_ec2_spot_event_capture" {
  rule     = aws_cloudwatch_event_rule.autospotting_regional_ec2_spot_event_capture.name
  arn      = data.aws_region.current.name == var.main_region ? data.aws_arn.autospotting_sqs_queue_arn.arn : var.event_bus_arn
  role_arn = data.aws_region.current.name == var.main_region ? "" : var.put_event_role_arn
  sqs_target {
    message_group_id = "autospotting_${module.label.id}"
  }
}


# Event rule for capturing Instance launch events
resource "aws_cloudwatch_event_rule" "autospotting_regional_ec2_instance_launch_event_capture" {
  name        = "autospotting_instance_launch_event_capture_${module.label.id}"
  description = "Capture EC2 instance launch events that are only fired within AWS regions and need to be forwarded to the central Lambda function"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "source": [
    "aws.ec2"
  ],
  "detail": {
    "state": [
      "running"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "autospotting_regional_ec2_instance_launch_event_capture" {
  rule     = aws_cloudwatch_event_rule.autospotting_regional_ec2_instance_launch_event_capture.name
  arn      = data.aws_region.current.name == var.main_region ? data.aws_arn.autospotting_sqs_queue_arn.arn : var.event_bus_arn
  role_arn = data.aws_region.current.name == var.main_region ? "" : var.put_event_role_arn
  sqs_target {
    message_group_id = "autospotting_${module.label.id}"
  }
}


# Event rule for capturing AutoScaling Lifecycle Hook events
resource "aws_cloudwatch_event_rule" "autospotting_regional_autoscaling_lifecycle_hook_event_capture" {
  name        = "autospotting_lifecycle_hook_event_capture_${module.label.id}"
  description = "This rule is triggered after we failed to complete a lifecycle hook. We capture in order to emulate the lifecycle hook for spot instances launched outside the ASG."

  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "source": [
    "aws.autoscaling"
  ],
  "detail": {
    "eventName": [
      "CompleteLifecycleAction"
    ],
    "errorCode": [
      "ValidationException"
    ],
    "requestParameters": {
      "lifecycleActionResult": [
        "CONTINUE"
      ]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "autospotting_regional_autoscaling_lifecycle_hook_event_capture" {
  rule     = aws_cloudwatch_event_rule.autospotting_regional_autoscaling_lifecycle_hook_event_capture.name
  arn      = data.aws_region.current.name == var.main_region ? data.aws_arn.autospotting_sqs_queue_arn.arn : var.event_bus_arn
  role_arn = data.aws_region.current.name == var.main_region ? "" : var.put_event_role_arn
  sqs_target {
    message_group_id = "autospotting_${module.label.id}"
  }
}

resource "aws_sqs_queue_policy" "autospotting_events_to_sqs" {
  count     = data.aws_region.current.name == var.main_region ? 1 : 0
  queue_url = var.autospotting_sqs_queue_url
  policy    = data.aws_iam_policy_document.autospotting_sqs_policy[0].json
}


data "aws_iam_policy_document" "autospotting_sqs_policy" {
  count   = data.aws_region.current.name == var.main_region ? 1 : 0
  version = "2012-10-17"

  statement {
    sid    = "AllowEventBridgeToSendSQSMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [data.aws_arn.autospotting_sqs_queue_arn.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.autospotting_regional_ec2_instance_launch_event_capture.arn,
        aws_cloudwatch_event_rule.autospotting_regional_ec2_spot_event_capture.arn,
        aws_cloudwatch_event_rule.autospotting_regional_autoscaling_lifecycle_hook_event_capture.arn,
      ]
    }
  }
}
