module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.21.0"
  context = var.label_context
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "regional_role" {
  name               = "iam_role_for_regional_regional_lambda-${module.label.id}"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "regional_lambda_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "regional_lambda_policy" {
  name   = "policy_for_${module.label.id}"
  role   = aws_iam_role.regional_role.id
  policy = data.aws_iam_policy_document.regional_lambda_policy.json
}
