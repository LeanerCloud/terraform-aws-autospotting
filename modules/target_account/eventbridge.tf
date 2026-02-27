locals {
  main_event_bus_arn = "arn:aws:events:${var.main_region}:${var.main_account_id}:event-bus/default"
}

# 1. Spot termination / rebalance events
resource "aws_cloudwatch_event_rule" "spot_events" {
  name        = "${var.name_prefix}_spot_event_capture"
  description = "Capture Spot market events and forward to main AutoSpotting account"

  event_pattern = jsonencode({
    "detail-type" = [
      "EC2 Spot Instance Interruption Warning",
      "EC2 Instance Rebalance Recommendation",
    ]
    source = ["aws.ec2"]
  })
}

resource "aws_cloudwatch_event_target" "spot_events" {
  rule     = aws_cloudwatch_event_rule.spot_events.name
  arn      = local.main_event_bus_arn
  role_arn = aws_iam_role.eventbridge_role.arn
}

# 2. Instance running events
resource "aws_cloudwatch_event_rule" "instance_launch" {
  name        = "${var.name_prefix}_instance_launch_event_capture"
  description = "Capture EC2 instance launch events and forward to main AutoSpotting account"

  event_pattern = jsonencode({
    "detail-type" = ["EC2 Instance State-change Notification"]
    source        = ["aws.ec2"]
    detail = {
      state = ["running"]
    }
  })
}

resource "aws_cloudwatch_event_target" "instance_launch" {
  rule     = aws_cloudwatch_event_rule.instance_launch.name
  arn      = local.main_event_bus_arn
  role_arn = aws_iam_role.eventbridge_role.arn
}

# 3. Lifecycle hook failure events
resource "aws_cloudwatch_event_rule" "lifecycle_hook" {
  name        = "${var.name_prefix}_lifecycle_hook_event_capture"
  description = "Capture failed lifecycle hook completions and forward to main AutoSpotting account"

  event_pattern = jsonencode({
    "detail-type" = ["AWS API Call via CloudTrail"]
    source        = ["aws.autoscaling"]
    detail = {
      eventName = ["CompleteLifecycleAction"]
      errorCode = ["ValidationException"]
      requestParameters = {
        lifecycleActionResult = ["CONTINUE"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lifecycle_hook" {
  rule     = aws_cloudwatch_event_rule.lifecycle_hook.name
  arn      = local.main_event_bus_arn
  role_arn = aws_iam_role.eventbridge_role.arn
}

# 4. ICE (InsufficientInstanceCapacity) error events
resource "aws_cloudwatch_event_rule" "ice_errors" {
  name        = "${var.name_prefix}_ice_error_event_capture"
  description = "Capture EC2 launch failures due to InsufficientInstanceCapacity"

  event_pattern = jsonencode({
    "detail-type" = ["AWS API Call via CloudTrail"]
    source        = ["aws.ec2"]
    detail = {
      eventName = ["RunInstances", "CreateFleet"]
      errorCode = [
        "InsufficientInstanceCapacity",
        "InsufficientHostCapacity",
        "Unsupported",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "ice_errors" {
  rule     = aws_cloudwatch_event_rule.ice_errors.name
  arn      = local.main_event_bus_arn
  role_arn = aws_iam_role.eventbridge_role.arn
}

# 5. Registration signal: CloudTrail PutRule events for autospotting-prefixed rules
# This event is forwarded to the main account to trigger auto-registration
resource "aws_cloudwatch_event_rule" "registration_signal" {
  name        = "${var.name_prefix}_registration_signal"
  description = "Forward PutRule events for autospotting-prefixed rules to main account for auto-registration"

  event_pattern = jsonencode({
    "detail-type" = ["AWS API Call via CloudTrail"]
    source        = ["aws.events"]
    detail = {
      eventName = ["PutRule"]
      requestParameters = {
        name = [{ prefix = "autospotting" }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "registration_signal" {
  rule     = aws_cloudwatch_event_rule.registration_signal.name
  arn      = local.main_event_bus_arn
  role_arn = aws_iam_role.eventbridge_role.arn
}
