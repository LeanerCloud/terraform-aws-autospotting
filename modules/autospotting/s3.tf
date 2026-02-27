# ──── S3 Buckets (conditional on enable_cost_dashboard) ────

resource "aws_s3_bucket" "audit" {
  count         = var.enable_cost_dashboard ? 1 : 0
  bucket        = "${module.label.id}-audit-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-Audit"
  })
}

resource "aws_s3_bucket_versioning" "audit" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket" "cost_history" {
  count         = var.enable_cost_dashboard ? 1 : 0
  bucket        = "${module.label.id}-cost-history-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CostHistory"
  })
}

resource "aws_s3_bucket_versioning" "cost_history" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_history[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cost_history" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_history[0].id

  rule {
    id     = "intelligent-tiering-and-expiry"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "cost_history" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_history[0].id
  name   = "ArchiveOldData"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

resource "aws_s3_bucket_logging" "cost_history" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_history[0].id

  target_bucket = aws_s3_bucket.audit[0].id
  target_prefix = "cost-history-access-logs/"
}

resource "aws_s3_bucket_public_access_block" "cost_history" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_history[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cost_history" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_history[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket" "cost_dashboard" {
  count         = var.enable_cost_dashboard ? 1 : 0
  bucket        = "${module.label.id}-dashboard-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CostDashboard"
  })
}

resource "aws_s3_bucket_logging" "cost_dashboard" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_dashboard[0].id

  target_bucket = aws_s3_bucket.audit[0].id
  target_prefix = "cost-dashboard-access/"
}

resource "aws_s3_bucket_public_access_block" "cost_dashboard" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_dashboard[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cost_dashboard" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_dashboard[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
