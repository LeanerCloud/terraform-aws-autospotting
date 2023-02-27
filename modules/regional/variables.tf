
variable "autospotting_lambda_arn" {}
variable "regions" {
  description = "Regions to handle"
  type        = list(string)
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

