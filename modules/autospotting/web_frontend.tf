# ──── CloudFront + Route53 + ACM (conditional on enable_cost_dashboard) ────

# Lambda Function URL for API backend
resource "aws_lambda_function_url" "dashboard_api" {
  count              = var.enable_cost_dashboard ? 1 : 0
  function_name      = aws_lambda_function.autospotting.function_name
  authorization_type = "AWS_IAM"
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3" {
  count                             = var.enable_cost_dashboard ? 1 : 0
  name                              = "${module.label.id}-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Origin Access Control for Lambda Function URL
resource "aws_cloudfront_origin_access_control" "lambda" {
  count                             = var.enable_cost_dashboard ? 1 : 0
  name                              = "${module.label.id}-lambda-oac"
  description                       = "OAC for Lambda Function URL"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Allow CloudFront to invoke the Lambda Function URL
resource "aws_lambda_permission" "cloudfront_invoke" {
  count                  = var.enable_cost_dashboard ? 1 : 0
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.autospotting.function_name
  principal              = "cloudfront.amazonaws.com"
  source_arn             = aws_cloudfront_distribution.dashboard[0].arn
  function_url_auth_type = "AWS_IAM"
}

# CloudFront function for SPA routing (serves index.html for all non-file paths)
resource "aws_cloudfront_function" "spa_routing" {
  count   = var.enable_cost_dashboard ? 1 : 0
  name    = "${replace(module.label.id, "-", "_")}_spa_routing"
  runtime = "cloudfront-js-2.0"
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Don't modify API requests
      if (uri.startsWith('/api/')) {
        return request;
      }

      // Rewrite all non-file requests to index.html for SPA routing
      if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
      } else if (!uri.includes('.')) {
        request.uri = '/index.html';
      }

      return request;
    }
  EOF
}

# CloudFront function to strip /api prefix for Lambda origin
resource "aws_cloudfront_function" "api_prefix_strip" {
  count   = var.enable_cost_dashboard ? 1 : 0
  name    = "${replace(module.label.id, "-", "_")}_api_prefix_strip"
  runtime = "cloudfront-js-2.0"
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Strip /api prefix if present (e.g., /api/v1/auth/login -> /v1/auth/login)
      if (uri.startsWith('/api/')) {
        request.uri = uri.substring(4);
      }

      return request;
    }
  EOF
}

locals {
  s3_origin_id     = "S3Origin"
  lambda_origin_id = "LambdaOrigin"
  lambda_domain    = var.enable_cost_dashboard ? replace(replace(aws_lambda_function_url.dashboard_api[0].function_url, "https://", ""), "/", "") : ""
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "dashboard" {
  count   = var.enable_cost_dashboard ? 1 : 0
  enabled = true

  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = var.dashboard_domain_name != "" ? [var.dashboard_domain_name] : []

  # S3 origin for static assets
  origin {
    domain_name              = aws_s3_bucket.cost_dashboard[0].bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3[0].id
  }

  # Lambda origin for API (using OAC for IAM-authenticated invocation)
  origin {
    domain_name              = local.lambda_domain
    origin_id                = local.lambda_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.lambda[0].id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior: S3 static assets with SPA routing
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_routing[0].arn
    }
  }

  # API behavior: forward to Lambda (no caching, forward all viewer headers except Host)
  ordered_cache_behavior {
    path_pattern             = "/api/*"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = local.lambda_origin_id
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_prefix_strip[0].arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.has_custom_domain
    acm_certificate_arn            = local.has_custom_domain ? aws_acm_certificate.dashboard[0].arn : null
    ssl_support_method             = local.has_custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.has_custom_domain ? "TLSv1.2_2021" : null
  }

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-CostDashboard"
  })

  depends_on = [aws_acm_certificate_validation.dashboard]
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cost_dashboard" {
  count  = var.enable_cost_dashboard ? 1 : 0
  bucket = aws_s3_bucket.cost_dashboard[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cost_dashboard[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.dashboard[0].arn
          }
        }
      }
    ]
  })
}

# ──── Route53 + ACM (conditional on dashboard_domain_name) ────

resource "aws_route53_zone" "dashboard" {
  count = var.enable_cost_dashboard && var.create_hosted_zone && var.hosted_zone_domain_name != "" ? 1 : 0
  name  = var.hosted_zone_domain_name
}

locals {
  hosted_zone_id = (
    var.create_hosted_zone && var.hosted_zone_domain_name != ""
    ? try(aws_route53_zone.dashboard[0].zone_id, "")
    : var.dashboard_hosted_zone_id
  )
  has_custom_domain = var.enable_cost_dashboard && var.dashboard_domain_name != "" && local.hosted_zone_id != ""
}

resource "aws_acm_certificate" "dashboard" {
  count             = local.has_custom_domain ? 1 : 0
  domain_name       = var.dashboard_domain_name
  validation_method = "DNS"

  tags = merge(module.label.tags, {
    Name = "${module.label.id}-DashboardCert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dashboard_cert_validation" {
  for_each = local.has_custom_domain ? {
    for dvo in aws_acm_certificate.dashboard[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = local.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "dashboard" {
  count                   = local.has_custom_domain ? 1 : 0
  certificate_arn         = aws_acm_certificate.dashboard[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dashboard_cert_validation : record.fqdn]
}

resource "aws_route53_record" "dashboard" {
  count   = local.has_custom_domain ? 1 : 0
  zone_id = local.hosted_zone_id
  name    = var.dashboard_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.dashboard[0].domain_name
    zone_id                = aws_cloudfront_distribution.dashboard[0].hosted_zone_id
    evaluate_target_health = false
  }
}
