variable "lambda_timeout" {}
variable "lambda_memory_size" {}
variable "lambda_source_ecr" {}
variable "lambda_source_image" {}
variable "lambda_source_image_tag" {}
variable "sqs_fifo_queue_name" {}

variable "autospotting_allowed_instance_types" {}
variable "autospotting_bidding_policy" {}
variable "autospotting_cron_schedule_state" {}
variable "autospotting_cron_schedule" {}
variable "autospotting_cron_timezone" {}
variable "autospotting_disable_event_based_instance_replacement" {}
variable "autospotting_disable_instance_rebalance_recommendation" {}
variable "autospotting_disallowed_instance_types" {}
variable "autospotting_ebs_gp2_conversion_threshold" {}
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
    label_key_case      = string
    label_value_case    = string
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
    label_key_case      = "lower"
    label_value_case    = "lower"
  }
}

