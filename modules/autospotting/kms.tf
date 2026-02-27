# ──── KMS Keys (conditional on enable_kms_encryption) ────

resource "aws_kms_key" "dynamodb" {
  count                   = var.enable_kms_encryption ? 1 : 0
  description             = "Customer-managed KMS key for DynamoDB table encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMPolicies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:RetireGrant",
          "kms:RevokeGrant",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowDynamoDBToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "dynamodb.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-DynamoDB-Key"
  })
}

resource "aws_kms_alias" "dynamodb" {
  count         = var.enable_kms_encryption ? 1 : 0
  name          = "alias/${module.label.id}-dynamodb-key"
  target_key_id = aws_kms_key.dynamodb[0].key_id
}

resource "aws_kms_key" "sns" {
  count                   = var.enable_kms_encryption ? 1 : 0
  description             = "KMS key for SNS topic encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMPolicies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:RetireGrant",
          "kms:RevokeGrant",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSNSToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "sns.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-SNS-Key"
  })
}

resource "aws_kms_alias" "sns" {
  count         = var.enable_kms_encryption ? 1 : 0
  name          = "alias/${module.label.id}-sns-key"
  target_key_id = aws_kms_key.sns[0].key_id
}
