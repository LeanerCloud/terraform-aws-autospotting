# ──── Core Tables (always created, matching CFN behavior) ────
#
# These tables are always created regardless of enable_multi_account because the
# Go binary references them unconditionally (Locking, DeferredActions for deferred
# spot replacements, CustomerAccounts for account tracking even in single-account mode).

moved {
  from = aws_dynamodb_table.customer_accounts[0]
  to   = aws_dynamodb_table.customer_accounts
}

moved {
  from = aws_dynamodb_table.companies[0]
  to   = aws_dynamodb_table.companies
}

moved {
  from = aws_dynamodb_table.blocked_accounts[0]
  to   = aws_dynamodb_table.blocked_accounts
}

moved {
  from = aws_dynamodb_table.rate_limit[0]
  to   = aws_dynamodb_table.rate_limit
}

moved {
  from = aws_dynamodb_table.locking[0]
  to   = aws_dynamodb_table.locking
}

moved {
  from = aws_dynamodb_table.deferred_actions[0]
  to   = aws_dynamodb_table.deferred_actions
}

resource "aws_dynamodb_table" "customer_accounts" {
  name         = "${module.label.id}-CustomerAccounts-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "AccountId"

  attribute {
    name = "AccountId"
    type = "S"
  }

  attribute {
    name = "CompanyId"
    type = "S"
  }

  attribute {
    name = "ApprovalStatus"
    type = "S"
  }

  attribute {
    name = "RegisteredAt"
    type = "S"
  }

  attribute {
    name = "OwnedBy"
    type = "S"
  }

  global_secondary_index {
    name            = "CompanyIdIndex"
    hash_key        = "CompanyId"
    range_key       = "AccountId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ApprovalStatusIndex"
    hash_key        = "ApprovalStatus"
    range_key       = "RegisteredAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "OwnedByIndex"
    hash_key        = "OwnedBy"
    range_key       = "AccountId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CustomerAccounts"
  })
}

resource "aws_dynamodb_table" "companies" {
  name         = "${module.label.id}-Companies-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CompanyId"

  attribute {
    name = "CompanyId"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-Companies"
  })
}

resource "aws_dynamodb_table" "blocked_accounts" {
  name         = "${module.label.id}-BlockedAccounts-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "AccountId"

  attribute {
    name = "AccountId"
    type = "S"
  }

  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-BlockedAccounts"
  })
}

resource "aws_dynamodb_table" "rate_limit" {
  name         = "${module.label.id}-RateLimit-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-RateLimit"
  })
}

resource "aws_dynamodb_table" "locking" {
  name         = "${module.label.id}-Locking-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockKey"

  attribute {
    name = "LockKey"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-Locking"
  })
}

resource "aws_dynamodb_table" "deferred_actions" {
  name         = "${module.label.id}-DeferredActions-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ActionKey"

  attribute {
    name = "ActionKey"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  stream_enabled   = true
  stream_view_type = "OLD_IMAGE"

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name    = "${module.label.id}-DeferredActions"
    Purpose = "Deferred action scheduling via DynamoDB TTL for AutoSpotting"
  })
}

# ──── Cost Dashboard Tables (conditional on enable_cost_dashboard) ────

resource "aws_dynamodb_table" "cost_snapshots" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-CostSnapshots-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "account_id"
  range_key    = "sort_key"

  attribute {
    name = "account_id"
    type = "S"
  }

  attribute {
    name = "sort_key"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CostSnapshots"
  })
}

resource "aws_dynamodb_table" "global_config" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-GlobalConfig-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-GlobalConfig"
  })
}

resource "aws_dynamodb_table" "users" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-Users-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  attribute {
    name = "GSI2PK"
    type = "S"
  }

  attribute {
    name = "GSI2SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI2"
    hash_key        = "GSI2PK"
    range_key       = "GSI2SK"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-Users"
  })
}

resource "aws_dynamodb_table" "company_memberships" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-CompanyMemberships-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CompanyMemberships"
  })
}

resource "aws_dynamodb_table" "invitations" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-Invitations-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Token"

  attribute {
    name = "Token"
    type = "S"
  }

  attribute {
    name = "Email"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "Email"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-Invitations"
  })
}

resource "aws_dynamodb_table" "invoices" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-Invoices-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "InvoiceId"

  attribute {
    name = "InvoiceId"
    type = "S"
  }

  attribute {
    name = "CompanyId"
    type = "S"
  }

  attribute {
    name = "Period"
    type = "S"
  }

  global_secondary_index {
    name            = "CompanyPeriodIndex"
    hash_key        = "CompanyId"
    range_key       = "Period"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-Invoices"
  })
}

resource "aws_dynamodb_table" "company_settings" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-CompanySettings-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CompanySettings"
  })
}

resource "aws_dynamodb_table" "account_settings" {
  count        = var.enable_cost_dashboard ? 1 : 0
  name         = "${module.label.id}-AccountSettings-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-AccountSettings"
  })
}

# ──── RISP Coverage Table (conditional on enable_risp_coverage) ────

resource "aws_dynamodb_table" "risp_coverage" {
  count        = var.enable_risp_coverage ? 1 : 0
  name         = "${module.label.id}-RISPCoverage-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-RISPCoverage"
  })
}
