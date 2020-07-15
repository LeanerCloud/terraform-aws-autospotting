
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

resource "aws_cloudwatch_event_rule" "autospotting_regional_event_capture" {
  name        = "${var.label_id}-regional_events"
  description = "Capture relevant events that are only fired within AWS regions and need to be forwarded to the central Lambda function"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "EC2 Spot Instance Interruption Warning"
  ],
  "source": [
    "aws.ec2"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.autospotting_regional_event_capture.name
  arn  = aws_lambda_function.regional_lambda.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_file = "${path.module}/handler.py"
}

resource "aws_lambda_function" "regional_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.label_id}-regional_lambda"
  role          = var.lambda_iam_role.arn
  handler       = "handler.handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.7"
  timeout = 300

  environment {
    variables = {
      AUTOSPOTTING_LAMBDA_ARN = var.autospotting_lambda_arn
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "${var.label_id}-AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.regional_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.autospotting_regional_event_capture.arn
}


