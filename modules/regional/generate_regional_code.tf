data "aws_regions" "current" {}

locals {
  all_regions = data.aws_regions.current.names
}

resource "local_file" "providers_tf" {
  content  = templatefile("${path.module}/providers.tmpl", { regions = local.all_regions })
  filename = "${path.module}/providers.tf"
}

resource "local_file" "regional_tf" {
  content  = templatefile("${path.module}/regional.tmpl", { regions = local.all_regions })
  filename = "${path.module}/regional.tf"
}
