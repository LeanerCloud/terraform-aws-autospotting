variable "lambda_zipname" {
  default = null
}

variable "lambda_s3_bucket" {
  default = null
}

variable "lambda_s3_key" {
  default = null
}

variable "lambda_manage_asg_s3_key" {}

variable "lambda_runtime" {}
variable "lambda_timeout" {}
variable "lambda_memory_size" {}

variable "autospotting_allowed_instance_types" {}
variable "autospotting_bidding_policy" {}
variable "autospotting_cron_schedule_state" {}
variable "autospotting_cron_schedule" {}
variable "autospotting_cron_timezone" {}
variable "autospotting_disallowed_instance_types" {}
variable "autospotting_instance_termination_method" {}
variable "autospotting_license" {}
variable "autospotting_min_on_demand_number" {}
variable "autospotting_min_on_demand_percentage" {}
variable "autospotting_on_demand_price_multiplier" {}
variable "autospotting_patch_beanswalk_userdata" {}
variable "autospotting_regions_enabled" {}
variable "autospotting_spot_price_buffer_percentage" {}
variable "autospotting_spot_product_description" {}
variable "autospotting_spot_product_premium" {}
variable "autospotting_tag_filtering_mode" {}
variable "autospotting_tag_filters" {}
variable "autospotting_termination_notification_action" {}

variable "lambda_tags" {
  description = "Tags to be applied to the Lambda function"
  type        = map(string)
}

# Label configuration
variable "label_context" {
  description = "Used to pass in label module context"
  type = object({
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
    id_length_limit     = number
  })
  default = {
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
    id_length_limit     = 0
  }
}

