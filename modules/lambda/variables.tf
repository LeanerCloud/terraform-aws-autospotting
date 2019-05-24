variable "lambda_zipname" {
  default = ""
}

variable "lambda_s3_bucket" {
  default = ""
}

variable "lambda_s3_key" {
  default = ""
}

variable "lambda_role_arn" {}
variable "lambda_runtime" {}
variable "lambda_timeout" {}
variable "lambda_memory_size" {}

variable "autospotting_allowed_instance_types" {}
variable "autospotting_disallowed_instance_types" {}
variable "autospotting_instance_termination_method" {}
variable "autospotting_min_on_demand_number" {}
variable "autospotting_min_on_demand_percentage" {}
variable "autospotting_on_demand_price_multiplier" {}
variable "autospotting_spot_price_buffer_percentage" {}
variable "autospotting_spot_product_description" {}
variable "autospotting_bidding_policy" {}
variable "autospotting_regions_enabled" {}
variable "autospotting_tag_filters" {}
variable "autospotting_tag_filtering_mode" {}

variable "lambda_tags" {
  description = "Tags to be applied to the Lambda function"
  type        = map(string)
}

# Label configuration
variable "label_context" {
  description = "Used to pass in label module context"
  type        = object({
    namespace           = string
    environment         = string
    stage               = string
    name                = string
    enabled             = bool
    delimiter           = string
    attributes          = list(string)
    label_order         = list(string)
    tags                = map(string)
    additional_tag_map  = map(string)
    regex_replace_chars = string
  })
  default     = {
    namespace           = ""
    environment         = ""
    stage               = ""
    name                = ""
    enabled             = true
    delimiter           = ""
    attributes          = []
    label_order         = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = ""
  }
}

