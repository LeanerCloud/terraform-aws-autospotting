# This file is generated, do not edit it directly.
# To update it execute "go run generate.go"


module "regional_resources_ap-northeast-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "ap-northeast-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_ap-northeast-2" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "ap-northeast-2"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_ap-south-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "ap-south-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_ap-southeast-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "ap-southeast-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_ap-southeast-2" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "ap-southeast-2"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_ca-central-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "ca-central-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_eu-central-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "eu-central-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_eu-north-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "eu-north-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_eu-west-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "eu-west-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_eu-west-2" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "eu-west-2"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_eu-west-3" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "eu-west-3"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_sa-east-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "sa-east-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_us-east-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "us-east-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_us-east-2" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "us-east-2"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_us-west-1" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "us-west-1"
    source                  = "./resources"
    label_id                = module.label.id
}

module "regional_resources_us-west-2" {
    autospotting_lambda_arn = var.autospotting_lambda_arn
    lambda_iam_role         = aws_iam_role.iam_for_lambda
    region                  = "us-west-2"
    source                  = "./resources"
    label_id                = module.label.id
}

