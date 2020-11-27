data "aws_regions" "current" {
  all_regions = true
}

locals {
  all_regions         = data.aws_regions.current.names
  unsupported_regions = ["ap-northeast-3"] # These regions currently throw an error when attempting to use them.

  all_usable_regions = setsubtract(local.all_regions, local.unsupported_regions)
}


resource "local_file" "providers_tf" {
  content  = templatefile("${path.module}/providers.tmpl", { regions = local.all_usable_regions })
  filename = "${path.module}/providers.tf"
}

resource "local_file" "regional_tf" {
  content  = templatefile("${path.module}/regional.tmpl", { regions = var.regions })
  filename = "${path.module}/regional.tf"
}