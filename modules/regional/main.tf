module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.21.0"
  context = var.label_context
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_role_for_regional_lambda-${module.label.id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

