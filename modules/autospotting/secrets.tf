# ──── Secrets Manager (conditional on enable_cost_dashboard) ────

resource "aws_secretsmanager_secret" "dashboard_api_key" {
  count       = var.enable_cost_dashboard ? 1 : 0
  name        = "${module.label.id}-dashboard-api-key-${random_id.suffix.hex}"
  description = "API key for Cost Dashboard authentication"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-DashboardAPIKey"
  })
}

resource "random_password" "dashboard_api_key" {
  count   = var.enable_cost_dashboard ? 1 : 0
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "dashboard_api_key" {
  count         = var.enable_cost_dashboard ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dashboard_api_key[0].id
  secret_string = random_password.dashboard_api_key[0].result
}

resource "aws_secretsmanager_secret" "token_hashing" {
  count       = var.enable_cost_dashboard ? 1 : 0
  name        = "${module.label.id}-token-hashing-${random_id.suffix.hex}"
  description = "Secret key for token hashing"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-TokenHashing"
  })
}

resource "random_password" "token_hashing" {
  count   = var.enable_cost_dashboard ? 1 : 0
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret_version" "token_hashing" {
  count         = var.enable_cost_dashboard ? 1 : 0
  secret_id     = aws_secretsmanager_secret.token_hashing[0].id
  secret_string = random_password.token_hashing[0].result
}

resource "aws_secretsmanager_secret" "stripe_api_key" {
  count       = var.enable_cost_dashboard ? 1 : 0
  name        = "${module.label.id}-stripe-api-key-${random_id.suffix.hex}"
  description = "Stripe API key - replace dummy value with real key from https://dashboard.stripe.com/apikeys"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-StripeAPIKey"
  })
}

resource "aws_secretsmanager_secret_version" "stripe_api_key" {
  count         = var.enable_cost_dashboard ? 1 : 0
  secret_id     = aws_secretsmanager_secret.stripe_api_key[0].id
  secret_string = "sk_test_DUMMY_REPLACE_THIS_VALUE_IN_SECRETS_MANAGER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "stripe_webhook_secret" {
  count       = var.enable_cost_dashboard ? 1 : 0
  name        = "${module.label.id}-stripe-webhook-secret-${random_id.suffix.hex}"
  description = "Stripe webhook secret - replace dummy value"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-StripeWebhookSecret"
  })
}

resource "aws_secretsmanager_secret_version" "stripe_webhook_secret" {
  count         = var.enable_cost_dashboard ? 1 : 0
  secret_id     = aws_secretsmanager_secret.stripe_webhook_secret[0].id
  secret_string = "whsec_DUMMY_REPLACE_THIS_VALUE_IN_SECRETS_MANAGER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "stripe_publishable_key" {
  count       = var.enable_cost_dashboard ? 1 : 0
  name        = "${module.label.id}-stripe-publishable-key-${random_id.suffix.hex}"
  description = "Stripe publishable key - replace dummy value"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-StripePublishableKey"
  })
}

resource "aws_secretsmanager_secret_version" "stripe_publishable_key" {
  count         = var.enable_cost_dashboard ? 1 : 0
  secret_id     = aws_secretsmanager_secret.stripe_publishable_key[0].id
  secret_string = "pk_test_DUMMY_REPLACE_THIS_VALUE_IN_SECRETS_MANAGER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "stripe_price_id" {
  count       = var.enable_cost_dashboard ? 1 : 0
  name        = "${module.label.id}-stripe-price-id-${random_id.suffix.hex}"
  description = "Stripe price ID - replace dummy value"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-StripePriceID"
  })
}

resource "aws_secretsmanager_secret_version" "stripe_price_id" {
  count         = var.enable_cost_dashboard ? 1 : 0
  secret_id     = aws_secretsmanager_secret.stripe_price_id[0].id
  secret_string = "price_DUMMY_REPLACE_THIS_VALUE_IN_SECRETS_MANAGER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
