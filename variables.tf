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

variable "autospotting_instance_termination_method" {
  description = <<EOF
Instance termination method. Must be one of 'autoscaling' (default) or
'detach' (compatibility mode, not recommended).
EOF
  default     = "autoscaling"
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

variable "autospotting_patch_beanswalk_userdata" {
  description = <<EOF
Controls whether AutoSpotting patches Elastic Beanstalk UserData
        scripts to use the instance role when calling CloudFormation helpers
        instead of the standard CloudFormation authentication method.
        After creating this CloudFormation stack, you must add the
        AutoSpotting's ElasticBeanstalk managed policy to your Beanstalk
        instance profile/role if you turn this option to true
EOF
  type        = bool
  default     = false
}

variable "autospotting_spot_product_description" {
  description = <<EOF
The Spot Product or operating system to use when looking
up spot price history in the market.

Valid choices
- Linux/UNIX | SUSE Linux | Windows
- Linux/UNIX (Amazon VPC) | SUSE Linux (Amazon VPC) | Windows (Amazon VPC)
EOF
  default     = "Linux/UNIX (Amazon VPC)"
}

variable "autospotting_spot_product_premium" {

  description = <<EOF
The Product Premium hourly charge to apply to the on demand price to improve spot
selection and savings calculations when using a premium instance type
such as RHEL.
EOF
  type        = number
  default     = 0
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

variable "autospotting_license" {
  description = <<EOF
Autospotting License code. Allowed options are:
'evaluation', 'I_am_supporting_it_on_Patreon',
'I_contributed_to_development_within_the_last_year',
'I_built_it_from_source_code'
EOF
  default     = "evaluation"
}

# Lambda configuration
variable "lambda_zipname" {
  description = "Name of the archive, relative to the module"
  default     = null
}

variable "lambda_s3_bucket" {
  description = "Bucket which the archive is stored in"
  default     = "cloudprowess"
}

variable "lambda_s3_key" {
  description = "Key in S3 under which the archive of the main Lambda function is stored"
  default     = "nightly/lambda.zip"
}

variable "lambda_manage_asg_s3_key" {
  description = "Key in S3 under which the archive of the manage-asg Lambda function is stored"
  default     = "nightly/manage_asg.zip"
}

variable "lambda_runtime" {
  description = "Environment the lambda function runs in"
  default     = "go1.x"
}

variable "lambda_memory_size" {
  description = "Memory size allocated to the lambda run"
  default     = 1024
}

variable "lambda_timeout" {
  description = "Timeout after which the lambda timeout"
  default     = 300
}

variable "lambda_run_frequency" {
  description = "How frequent should lambda run"
  default     = "rate(5 minutes)"
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
  }
}
