variable "main_account_id" {
  description = "AWS account ID of the main AutoSpotting account"
  type        = string
}

variable "main_region" {
  description = "AWS region where the main AutoSpotting Lambda runs"
  type        = string
}

variable "autospotting_lambda_role_arn" {
  description = "ARN of the AutoSpotting Lambda execution role in the main account"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "autospotting"
}
