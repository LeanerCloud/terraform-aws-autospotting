locals {
  src_image = "${var.lambda_source_ecr}/${var.lambda_source_image}:${var.lambda_source_image_tag}"
  dst_image = "${aws_ecr_repository.autospotting.repository_url}:${var.lambda_source_image_tag}"
}
resource "aws_ecr_repository" "autospotting" {
  name                 = "autospotting-${module.label.id}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
  timeouts {
    delete = "2m"
  }
}

data "aws_ecr_authorization_token" "source" {
  count       = var.lambda_use_public_ecr ? 0 : 1
  registry_id = var.lambda_use_public_ecr ? null : split(".", var.lambda_source_ecr)[0]
  provider    = aws.us-east-1
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
data "aws_ecrpublic_authorization_token" "source" {
  count    = var.lambda_use_public_ecr ? 1 : 0
  provider = aws.us-east-1
}


data "aws_ecr_authorization_token" "destination" {}

provider "docker" {
  registry_auth {
    address  = var.lambda_source_ecr
    username = var.lambda_use_public_ecr ? data.aws_ecrpublic_authorization_token.source[0].user_name : data.aws_ecr_authorization_token.source[0].user_name
    password = var.lambda_use_public_ecr ? data.aws_ecrpublic_authorization_token.source[0].password : data.aws_ecr_authorization_token.source[0].password
  }
  registry_auth {
    address  = split("/", aws_ecr_repository.autospotting.repository_url)[0]
    username = data.aws_ecr_authorization_token.destination.user_name
    password = data.aws_ecr_authorization_token.destination.password
  }
}

resource "docker_image" "base_image" {
  name = local.src_image
}

resource "docker_tag" "image" {
  source_image = docker_image.base_image.name
  target_image = local.dst_image
}

resource "docker_registry_image" "destination" {
  name          = local.dst_image
  keep_remotely = false
  depends_on    = [docker_tag.image]
}
