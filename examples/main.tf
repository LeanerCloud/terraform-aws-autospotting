provider "aws" {
  region = "us-east-1"
}

module "autospotting-test" {
  source      = "../"
  name        = "AutoSpotting"
  environment = "test"
  # when this is commented out AutoSpotting will install regional resources in
  # all regions. After this value is changed, Terraform apply needs to be
  # executed twice because of the way we generate some Terraform code from
  # Terraform itself.
  # autospotting_regions_enabled = ["us-east-1", "eu-west-1"]
}

# This can be used to install a second instance of AutoSpotting with different
# parameters.

# Be careful when destroying additional modules, you will need to restore
# modules/regional/providers.tf and modules/regional/regional.tf from git
# history, as they are deleted on destroy.

# module "autospotting-dev" {
#   source      = "../"
#   name        = "AutoSpotting"
#   environment = "dev"
#   autospotting_regions_enabled = ["us-east-1", "eu-west-1"]
# }

output "regions" {
  value = module.autospotting-test.regions
}
