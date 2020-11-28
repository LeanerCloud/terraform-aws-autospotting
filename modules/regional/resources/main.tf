module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.21.0"
  context = var.label_context
}

# Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_file = "${path.module}/handler.py"
}

resource "aws_lambda_function" "regional_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "autospotting_regional_lambda_${module.label.id}"
  role          = var.lambda_iam_role.arn
  handler       = "handler.handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.8"
  timeout = 300

  environment {
    variables = {
      AUTOSPOTTING_LAMBDA_ARN = var.autospotting_lambda_arn
    }
  }
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
  rule = aws_cloudwatch_event_rule.autospotting_regional_ec2_spot_event_capture.name
  arn  = aws_lambda_function.regional_lambda.arn
}

resource "aws_lambda_permission" "autospotting_regional_ec2_spot_event_capture" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.regional_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.autospotting_regional_ec2_spot_event_capture.arn
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
  rule = aws_cloudwatch_event_rule.autospotting_regional_ec2_instance_launch_event_capture.name
  arn  = aws_lambda_function.regional_lambda.arn
}

resource "aws_lambda_permission" "autospotting_regional_ec2_instance_launch_event_capture" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.regional_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.autospotting_regional_ec2_instance_launch_event_capture.arn
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
  rule = aws_cloudwatch_event_rule.autospotting_regional_autoscaling_lifecycle_hook_event_capture.name
  arn  = aws_lambda_function.regional_lambda.arn
}

resource "aws_lambda_permission" "autospotting_regional_autoscaling_lifecycle_hook_event_capture" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.regional_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.autospotting_regional_autoscaling_lifecycle_hook_event_capture.arn
}

