# ──── Base IAM additions (always created) ────

# Additional base permissions: CloudTrail, S3 config bucket, core DynamoDB tables, STS
data "aws_iam_policy_document" "autospotting_policy_extended" {
  count = var.use_existing_iam_role ? 0 : 1

  statement {
    sid = "CloudTrailRead"
    actions = [
      "cloudtrail:LookupEvents",
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3ConfigBucketRead"
    actions = [
      "s3:GetObject",
    ]
    resources = ["arn:aws:s3:::autospotting-central-configuration/*"]
  }

  statement {
    sid = "SESsendEmail"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = ["alerts@autospotting.io"]
    }
  }

  statement {
    sid = "XRayPermissions"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }

  # Cross-account role assumption (always present, matching CFN LambdaPolicyExtended)
  statement {
    sid    = "AssumeCustomerRoles"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::*:role/AutoSpotting-Execution-Role",
      "arn:aws:iam::*:role/*-Execution-Role",
    ]
  }

  # Core DynamoDB tables (always created, matching CFN)
  statement {
    sid    = "DynamoDBCustomerAccounts"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.customer_accounts.arn,
      "${aws_dynamodb_table.customer_accounts.arn}/index/*",
    ]
  }

  statement {
    sid    = "DynamoDBCompanies"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.companies.arn,
    ]
  }

  statement {
    sid    = "DynamoDBBlockedAccounts"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.blocked_accounts.arn,
    ]
  }

  statement {
    sid    = "DynamoDBRateLimit"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.rate_limit.arn,
    ]
  }

  statement {
    sid    = "DynamoDBLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      aws_dynamodb_table.locking.arn,
    ]
  }

  statement {
    sid    = "DynamoDBDeferredActions"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
    ]
    resources = [
      aws_dynamodb_table.deferred_actions.arn,
    ]
  }

  statement {
    sid    = "DynamoDBDeferredActionsStream"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
    ]
    resources = [
      "${aws_dynamodb_table.deferred_actions.arn}/stream/*",
    ]
  }
}

resource "aws_iam_role_policy" "autospotting_policy_extended" {
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "policy_extended_${module.label.id}"
  role   = aws_iam_role.autospotting_role[0].id
  policy = data.aws_iam_policy_document.autospotting_policy_extended[0].json
}

# ──── Cost Dashboard IAM (conditional on enable_cost_dashboard) ────

data "aws_iam_policy_document" "cost_dashboard_policy" {
  count = !var.use_existing_iam_role && var.enable_cost_dashboard ? 1 : 0

  statement {
    sid    = "DynamoDBDashboardTables"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:BatchWriteItem",
    ]
    resources = [
      aws_dynamodb_table.cost_snapshots[0].arn,
      aws_dynamodb_table.global_config[0].arn,
      aws_dynamodb_table.users[0].arn,
      "${aws_dynamodb_table.users[0].arn}/index/*",
      aws_dynamodb_table.company_memberships[0].arn,
      "${aws_dynamodb_table.company_memberships[0].arn}/index/*",
      aws_dynamodb_table.invitations[0].arn,
      "${aws_dynamodb_table.invitations[0].arn}/index/*",
      aws_dynamodb_table.invoices[0].arn,
      "${aws_dynamodb_table.invoices[0].arn}/index/*",
      aws_dynamodb_table.company_settings[0].arn,
      aws_dynamodb_table.account_settings[0].arn,
    ]
  }

  statement {
    sid    = "S3CostHistoryBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.cost_history[0].arn,
      "${aws_s3_bucket.cost_history[0].arn}/*",
    ]
  }

  statement {
    sid    = "AthenaQueryExecution"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
    ]
    resources = [
      aws_athena_workgroup.cost_analytics[0].arn,
    ]
  }

  statement {
    sid    = "GlueCatalogAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:BatchCreatePartition",
      "glue:CreatePartition",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:catalog",
      aws_glue_catalog_database.cost_data[0].arn,
      "arn:aws:glue:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.cost_data[0].name}/*",
    ]
  }

  statement {
    sid    = "SecretsManagerGetSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.dashboard_api_key[0].arn,
      aws_secretsmanager_secret.token_hashing[0].arn,
      aws_secretsmanager_secret.stripe_api_key[0].arn,
      aws_secretsmanager_secret.stripe_webhook_secret[0].arn,
      aws_secretsmanager_secret.stripe_publishable_key[0].arn,
      aws_secretsmanager_secret.stripe_price_id[0].arn,
    ]
  }

  statement {
    sid    = "SESSendDashboardEmails"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.ses_from_address]
    }
  }

  statement {
    sid    = "SESVerificationAccess"
    effect = "Allow"
    actions = [
      "ses:GetIdentityVerificationAttributes",
      "ses:VerifyEmailIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cost_dashboard_policy" {
  count  = !var.use_existing_iam_role && var.enable_cost_dashboard ? 1 : 0
  name   = "policy_cost_dashboard_${module.label.id}"
  role   = aws_iam_role.autospotting_role[0].id
  policy = data.aws_iam_policy_document.cost_dashboard_policy[0].json
}

# ──── RISP Coverage IAM (conditional on enable_risp_coverage) ────

data "aws_iam_policy_document" "risp_coverage_policy" {
  count = !var.use_existing_iam_role && var.enable_risp_coverage ? 1 : 0

  statement {
    sid    = "CostExplorerRead"
    effect = "Allow"
    actions = [
      "ce:GetReservationCoverage",
      "ce:GetReservationUtilization",
      "ce:GetSavingsPlansCoverage",
      "ce:GetSavingsPlansUtilization",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2DescribeReservedInstances"
    effect = "Allow"
    actions = [
      "ec2:DescribeReservedInstances",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DynamoDBRISPCoverage"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      aws_dynamodb_table.risp_coverage[0].arn,
    ]
  }

  dynamic "statement" {
    for_each = var.risp_billing_account_role_arn != "" ? [1] : []
    content {
      sid    = "AssumeRISPBillingRole"
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
      ]
      resources = [
        var.risp_billing_account_role_arn,
      ]
    }
  }
}

resource "aws_iam_role_policy" "risp_coverage_policy" {
  count  = !var.use_existing_iam_role && var.enable_risp_coverage ? 1 : 0
  name   = "policy_risp_coverage_${module.label.id}"
  role   = aws_iam_role.autospotting_role[0].id
  policy = data.aws_iam_policy_document.risp_coverage_policy[0].json
}
