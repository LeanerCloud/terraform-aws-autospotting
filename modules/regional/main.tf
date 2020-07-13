module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.13.0"
  context = var.label_context
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${module.label.id}-iam_for_lambda"

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
