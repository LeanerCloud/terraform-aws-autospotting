module "label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.13.0"
  context = var.label_context
}

