# Autospotting configuration
variable "autospotting_allowed_instance_types" {
  description = <<EOF
Comma separated list of allowed instance types for spot requests,
in case you want to exclude specific types (also support globs).

Example: 't2.*,m4.large'

Using the 'current' magic value will only allow the same type as the
on-demand instances set in the group's launch configuration.
EOF
  default     = ""
}

variable "autospotting_allow_parallel_instance_replacements" {
  type        = string
  description = <<EOF
    Controls whether AutoSpotting should allow parallel instance replacements
    or force them to happen in sequence. This is by default disabled because
    it may require the increase of the Maximum capacity of the autoscaling
    group to double the desired capacity, and/or service quota increases for
    EC2 instances.
  EOF
  default     = "true"
  validation {
    condition     = contains(["true", "false"], var.autospotting_allow_parallel_instance_replacements)
    error_message = "Valid value is one of the following: true, false."
  }
}

variable "autospotting_automated_instance_data_update" {
  description = <<EOF
    Controls whether AutoSpotting should automatically update its embedded
    instance type data. This doesn't bring benefits for recently released
    builds and is slowing down the Lambda execution, but it may be useful
    later if you want to add support for newer instance types without
    updating AutoSpotting.
  EOF
  type        = string
  default     = "false"
  validation {
    condition     = contains(["true", "false"], var.autospotting_automated_instance_data_update)
    error_message = "Valid value is one of the following: true, false."
  }
}

variable "autospotting_consider_ebs_bandwidth" {
  type        = string
  description = <<EOF
    Controls whether AutoSpotting considers EBS Bandwidth when comparing
    instance types in order to determine compatibility with other instance
    types, default: false. Enabling this flag will reduce diversfication
    to only instance types offering at least as much EBS bandwidth as the
    initial instance type.
  EOF
  default     = "false"
  validation {
    condition     = contains(["true", "false"], var.autospotting_consider_ebs_bandwidth)
    error_message = "Valid value is one of the following: true, false."
  }
}

variable "autospotting_cron_schedule_state" {
  description = <<EOF
Controls whether or not to run AutoSpotting within a time interval
given in the 'autospotting_cron_schedule' parameter. Setting this to 'off'
would make it run only outside the defined interval. This is a global value
that can be overridden on a per-AutoScaling-group basis using the
'autospotting_cron_schedule_state' tag set on the AutoScaling group

Example: 'off'
EOF
  default     = "on"
}

variable "autospotting_cron_schedule" {
  description = <<EOF
Restrict AutoSpotting to run within a time interval given as a
simplified cron-like rule format restricted to hours and days of week.

Example: '9-18 1-5' would run it during the work-week and only within
the usual 9-18 office hours.

This is a global value that can be
overridden on a per-group basis using the 'autospotting_cron_schedule'
tag set on the AutoScaling group. The default value '* *' makes it run
at all times.
EOF
  default     = "* *"
}

variable "autospotting_cron_timezone" {
  description = <<EOF
Sets the timezone in which to check the CronSchedule.

Example: If the timezone is set to 'UTC' and the CronSchedule is '9-18 1-5'
 it would start the interval at 9AM UTC, with the timezone set to 'Europe/London'
it would start the interval at 9AM BST (10am UTC) or 9AM GMT (9AM UTC)
depending on daylight savings.

EOF
  default     = "UTC"
}


variable "autospotting_disallowed_instance_types" {
  description = <<EOF
Comma separated list of disallowed instance types for spot requests,
in case you want to exclude specific types (also support globs).

Example: 't2.*,m4.large'
EOF
  default     = ""
}

variable "notify_email_addresses" {
  description = <<EOF
    Addresses to receive notifications for AutoSpotting actions and savings reports.
  EOF
  type        = list(string)
}

variable "autospotting_enable_instance_rebalance_recommendation" {
  description = <<EOF
    Enables handling of instance rebalance recommendation events.
  EOF
  type        = string
  default     = "false"
  validation {
    condition     = contains(["true", "false"], var.autospotting_enable_instance_rebalance_recommendation)
    error_message = "Valid value is one of the following: true, false."
  }
}

variable "autospotting_instance_types_per_az" {
  type        = number
  default     = 1
  description = "Number of instance types to diversify over for each availability zone. Can be overridden on a per-group basis using the tag  'autospotting_number_of_instance_types_per_az'."
}

variable "autospotting_min_on_demand_number" {
  description = "Minimum on-demand instances to keep in absolute value"
  type        = number
  default     = 0
}

variable "autospotting_min_on_demand_percentage" {
  description = "Minimum on-demand instances to keep in percentage"
  type        = number
  default     = "0.0"
}

variable "autospotting_on_demand_price_multiplier" {
  description = "Multiplier for the on-demand price"
  type        = number
  default     = "1.0"
}

variable "autospotting_prioritized_instance_types_bias" {
  description = <<EOF
    Controls the ordering of instance types when using the capacity-optimized-prioritized
    Spot allocation strategy. By default, using the 'lowest_price' bias it sorts instances by
    Spot price, giving a softer preference than the 'lowest_price' Spot allocation strategy.
    Alternatively, you can prefer newer instance types by using the 'prefer_newer_generations'
    bias, which still orders instance types by price but penalizes instances from older
    generations by adding 10% to their hourly price for each older generation when considering
    them for the sorted list. For example, a C5 instance type will be penalized by 10% over C6i,
    while a C4 will be penalized by 20%.
  EOF
  type        = string
  default     = "prefer_newer_generations"
  validation {
    condition     = contains(["prefer_newer_generations", "lowest_price"], var.autospotting_prioritized_instance_types_bias)
    error_message = "Valid value is one of the following: prefer_newer_generations, lowest_price."
  }
}

variable "autospotting_savings_reports_frequency" {
  type        = string
  description = <<EOF
    Controls the frequency of the saving reports. Defaults to sending them daily.
    EOF
  validation {
    condition     = contains(["daily", "weekly", "monthly", "never"], var.autospotting_savings_reports_frequency)
    error_message = "Valid value is one of the following: daily, weekly, monthly, never."
  }
  default = "daily"
}

variable "autospotting_spot_allocation_strategy" {
  type        = string
  description = <<EOF
    Controls the Spot allocation strategy for launching Spot instances.
    Allowed options:
    'capacity-optimized-prioritized' (default), 'capacity-optimized',
    'lowest-price'. Further information on this is available at
    https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-fleet-allocation-strategy.html"
    EOF
  validation {
    condition     = contains(["capacity-optimized-prioritized", "capacity-optimized", "lowest-price"], var.autospotting_spot_allocation_strategy)
    error_message = "Valid value is one of the following: capacity-optimized-prioritized, capacity-optimized, lowest-price."
  }
  default = "capacity-optimized-prioritized"
}


variable "autospotting_spot_price_buffer_percentage" {
  description = "Percentage above the current spot price to place the bid"
  default     = "10.0"
}

variable "autospotting_termination_notification_action" {
  description = <<EOF
Action to do when receiving a Spot Instance Termination Notification.
Must be one of 'auto' (terminate if lifecycle hook is defined, or else
detach) [default], 'terminate' (lifecycle hook triggered), 'detach'
(lifecycle hook not triggered)

Allowed values: auto | detach | terminate
EOF
  default     = "auto"
}

variable "autospotting_bidding_policy" {
  description = "Bidding policy for the spot bid"
  default     = "normal"
}

variable "autospotting_regions_enabled" {
  description = "Regions in which autospotting is enabled"
  default     = []
}

variable "autospotting_tag_filters" {
  description = <<EOF
Tags to filter which ASGs autospotting considers. If blank
by default this will search for asgs with spot-enabled=true (when in opt-in
mode) and will skip those tagged with spot-enabled=false when in opt-out
mode.

You can set this to many tags, for example:
spot-enabled=true,Environment=dev,Team=vision
EOF
  default     = ""
}

variable "autospotting_tag_filtering_mode" {
  description = <<EOF
Controls the tag-based ASG filter. Supported values: 'opt-in' or 'opt-out'.
Defaults to opt-in mode, in which it only acts against the tagged groups. In
opt-out mode it works against all groups except for the tagged ones.
EOF
  default     = "opt-in"
}

# Lambda configuration

variable "lambda_source_ecr" {
  description = <<EOF
  ECR repository that stores the AutoSpotting Docker image used by
  Lambda. The default value is using the AWS Marketplace ECR repository
  and only works if you purchased AutoSpotting through the AWS
  Marketplace. If you built it yourself, you need to override this value
  with the URL of your own ECR repository that contains the AutoSpotting
  Docker image.
  EOF
  default     = "709825985650.dkr.ecr.us-east-1.amazonaws.com"
}

variable "lambda_source_image" {
  description = "The Docker image used for the Lambda function"
  default     = "cloudutil/autospotting"
}

variable "lambda_source_image_tag" {
  description = "The version of the Docker image used for the Lambda function"
  default     = "stable-1.3.0-0"
}


variable "lambda_memory_size" {
  description = "Memory size allocated to the lambda run"
  default     = 512
}

variable "lambda_cpu_architecture" {
  description = <<EOF
    The CPU architecture to use for running the AutoSpotting Docker image.
  EOF
  type        = string
  default     = "x86_64"
  validation {
    condition     = contains(["arm64", "x86_64"], var.lambda_cpu_architecture)
    error_message = "Valid value is one of the following: arm64, x86_64."
  }
}

variable "lambda_use_public_ecr" {
  type        = bool
  description = "Use a public ECR repo"
  default     = false
}


variable "lambda_timeout" {
  description = "Timeout after which the lambda timeout"
  default     = 900
}

variable "lambda_reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function"
  type        = number
  default     = 100
}

variable "lambda_enable_xray" {
  description = "Enable AWS X-Ray tracing for the Lambda function"
  type        = bool
  default     = false
}

variable "lambda_run_frequency" {
  description = "How frequent should lambda run"
  default     = "rate(30 minutes)"
}

variable "lambda_tags" {
  description = "Tags to be applied to the Lambda function"
  default = {
    # You can add more values below
    Name = "autospotting"
  }
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
    label_key_case      = "lower"
    label_value_case    = "lower"
  }
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

variable "permissions_boundary_arn" {
  description = "ARN of a permissions boundary resource"
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

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365
}

# Multi-account / SaaS configuration
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

variable "allowed_organizations" {
  description = "Comma-separated list of AWS Organization IDs allowed to use AutoSpotting"
  type        = string
  default     = ""
}

variable "allow_unrestricted_events" {
  description = "Allow any AWS account to send events to the default EventBridge bus"
  type        = bool
  default     = false
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
  default     = false
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

