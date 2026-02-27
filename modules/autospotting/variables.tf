variable "autospotting_allowed_instance_types" {}
variable "autospotting_bidding_policy" {}
variable "autospotting_cron_schedule_state" {}
variable "autospotting_cron_schedule" {}
variable "autospotting_cron_timezone" {}
variable "autospotting_disallowed_instance_types" {}
variable "autospotting_min_on_demand_number" {}
variable "autospotting_min_on_demand_percentage" {}
variable "autospotting_on_demand_price_multiplier" {}
variable "autospotting_regions_enabled" {}
variable "autospotting_spot_price_buffer_percentage" {}
variable "autospotting_tag_filtering_mode" {}
variable "autospotting_tag_filters" {}
variable "autospotting_termination_notification_action" {}

variable "autospotting_automated_instance_data_update" {
  type        = bool
  description = "Flag to control whether Autospotting should automatically download and use the latest instance types data."
}

variable "autospotting_consider_ebs_bandwidth" {
  type        = bool
  description = "Flag to control whether Autospotting should consider EBS bandwidth when selecting instance types."
}

variable "autospotting_enable_instance_rebalance_recommendation" {
  type        = bool
  description = "Flag to control whether Autospotting should recommend instance rebalance based on memory, CPU, and IO."
}

variable "autospotting_instance_types_per_az" {
  type        = number
  description = "Number of instance types to diversify over for each availability zone. Can be overridden on a per-group basis using the tag  'autospotting_number_of_instance_types_per_az'."
}

variable "autospotting_prioritized_instance_types_bias" {
  type        = string
  description = "Controls the Autospotting instance selection strategy. Valid values: 'prefer_newer_generations', 'lowest_price'."
  validation {
    condition     = contains(["prefer_newer_generations", "lowest_price"], var.autospotting_prioritized_instance_types_bias)
    error_message = "Invalid value for autospotting_prioritized_instance_types_bias. Allowed values: 'prefer_newer_generations', 'lowest_price'."
  }
}

variable "autospotting_savings_reports_frequency" {
  type        = string
  description = "Frequency of Autospotting cost savings reports. Valid values: 'daily', 'weekly', 'monthly', 'never'."
  validation {
    condition     = contains(["daily", "weekly", "monthly", "never"], var.autospotting_savings_reports_frequency)
    error_message = "Invalid value for autospotting_savings_reports_frequency. Allowed values: 'daily', 'weekly', 'monthly', 'never'."
  }
}

variable "autospotting_spot_allocation_strategy" {
  type        = string
  description = "Controls the Spot allocation strategy for launching Spot instances. Valid values: 'capacity-optimized-prioritized', 'capacity-optimized', 'lowest-price'."
  validation {
    condition     = contains(["capacity-optimized-prioritized", "capacity-optimized", "lowest-price"], var.autospotting_spot_allocation_strategy)
    error_message = "Invalid value for autospotting_spot_allocation_strategy. Allowed values: 'capacity-optimized-prioritized', 'capacity-optimized', 'lowest-price'."
  }
}

variable "lambda_timeout" {}
variable "lambda_memory_size" {}
variable "lambda_source_ecr" {}
variable "lambda_source_image" {}
variable "lambda_source_image_tag" {}

variable "lambda_use_public_ecr" {
  type        = bool
  description = "Use a public ECR repo"
}

variable "sqs_fifo_queue_name" {}

variable "lambda_tags" {
  description = "Tags to be applied to the Lambda function"
  type        = map(string)
}

variable "lambda_cpu_architecture" {
  type        = string
  description = "CPU architecture to use for the Autospotting Lambda function."
  validation {
    condition     = contains(["arm64", "x86_64"], var.lambda_cpu_architecture)
    error_message = "Invalid value for lambda_cpu_architecture. Allowed values: 'arm64', 'x86_64'."
  }
}

variable "automated_instance_data_update" {
  type    = bool
  default = false
}

variable "notify_email_addresses" {
  type        = list(string)
  description = "Email addresses to send Autospotting notifications to."
}


variable "use_existing_iam_role" {
  description = "Boolean flag to indicate whether to use an existing IAM role or create a new one for the Lambda function"
  type        = bool
  default     = false
}
variable "existing_iam_role_arn" {
  description = "ARN of an existing IAM role to use for the Lambda function"
  type        = string
  default     = ""
}


variable "use_existing_subnets" {
  description = "Boolean flag to indicate whether to use existing subnets or create new ones for the Lambda function"
  type        = bool
  default     = false
}

variable "existing_subnets" {
  description = "List of existing subnets to use for the Lambda function"
  type        = list(string)
  default     = []
}

variable "permissions_boundary_arn" {
  description = "ARN of a permissions boundary resource"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365
}

variable "lambda_reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function"
  type        = number
  default     = 100
}

variable "lambda_enable_xray" {
  description = "Enable AWS X-Ray tracing for the Lambda function"
  type        = bool
  default     = true
}

# Multi-account / SaaS
variable "enable_multi_account" {
  description = "Enable multi-account mode with DynamoDB tables for customer management"
  type        = bool
  default     = false
}

variable "allowed_customer_accounts" {
  description = "Comma-separated list of AWS account IDs allowed to use AutoSpotting"
  type        = string
  default     = ""
}

variable "customer_execution_role_name" {
  description = "Name of the IAM role in customer accounts that AutoSpotting assumes"
  type        = string
  default     = "AutoSpottingRole"
}

variable "pre_approved_companies" {
  description = "Comma-separated list of pre-approved company identifiers"
  type        = string
  default     = ""
}

variable "saas_mode" {
  description = "Enable SaaS mode features (billing, multi-company UI)"
  type        = bool
  default     = false
}

variable "enable_cost_dashboard" {
  description = "Enable cost dashboard with S3, Glue, CloudFront, and related infrastructure"
  type        = bool
  default     = false
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for DynamoDB tables and SNS topics"
  type        = bool
  default     = false
}

variable "admin_email" {
  description = "Admin email address for notifications and SES"
  type        = string
  default     = ""
}

variable "ses_from_address" {
  description = "Email address to use as the SES sender"
  type        = string
  default     = ""
}

variable "glue_database_name" {
  description = "Name for the Glue catalog database"
  type        = string
  default     = "autospotting_cost_data"
}

variable "dashboard_domain_name" {
  description = "Custom domain name for the cost dashboard CloudFront distribution"
  type        = string
  default     = ""
}

variable "dashboard_hosted_zone_id" {
  description = "Route53 hosted zone ID for the dashboard domain"
  type        = string
  default     = ""
}

variable "create_hosted_zone" {
  description = "Create a new Route53 hosted zone for the dashboard domain"
  type        = bool
  default     = false
}

variable "hosted_zone_domain_name" {
  description = "Domain name for the new Route53 hosted zone"
  type        = string
  default     = ""
}

variable "deploy_fargate" {
  description = "Deploy Fargate resources for billing tasks"
  type        = bool
  default     = true
}

variable "create_service_linked_roles" {
  description = "Create AWS service-linked roles for Spot and ECS"
  type        = bool
  default     = true
}

variable "autospotting_handle_lifecycle_hook_events" {
  description = "Enable handling of ASG lifecycle hook events"
  type        = bool
  default     = true
}

# RISP Coverage
variable "enable_risp_coverage" {
  description = "Enable Reserved Instance and Savings Plans coverage monitoring"
  type        = bool
  default     = false
}

variable "risp_billing_account_role_arn" {
  description = "ARN of the IAM role in the billing account for cost data access"
  type        = string
  default     = ""
}

variable "risp_coverage_threshold" {
  description = "Threshold percentage for RISP coverage alerts"
  type        = number
  default     = 80
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


