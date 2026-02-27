
locals {
  task_role_arn      = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : aws_iam_role.autospotting_task_execution[0].arn
  execution_role_arn = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : aws_iam_role.autospotting_task_execution[0].arn
}

data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}

module "vpc" {
  count   = var.use_existing_subnets ? 0 : 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.21"

  name = "autospotting-${module.label.id}"

  cidr = "10.0.0.0/24"

  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets = ["10.0.0.0/25", "10.0.0.128/25"]

  enable_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true
}

resource "aws_ecs_cluster" "autospotting" {
  name = "autospotting-${module.label.id}"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.autospotting.name

  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}


resource "aws_ecs_task_definition" "autospotting_task_definition" {
  family                   = "${module.label.id}-task-definition"
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  runtime_platform {
    cpu_architecture = var.lambda_cpu_architecture == "arm64" ? "ARM64" : "X86_64"
  }

  container_definitions = jsonencode([{
    name  = "autospotting-${module.label.id}"
    image = "${aws_ecr_repository.autospotting.repository_url}:${var.lambda_source_image_tag}"


    environment = [{
      name  = "AUTOMATED_INSTANCE_DATA_UPDATE"
      value = tostring(var.automated_instance_data_update)
      }, {
      name  = "BILLING_ONLY"
      value = "true"
      }, {
      name  = "NOTIFICATION_SNS_TOPIC"
      value = aws_sns_topic.email_notification.arn
      }, {
      name  = "SAVINGS_REPORTS_FREQUENCY"
      value = var.autospotting_savings_reports_frequency
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.autospotting.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "autospotting-billing" // This is a prefix used in the names of the log streams
      }
    }
  }])

  tags = module.label.tags
}

resource "aws_iam_role" "autospotting_task_execution" {
  count = var.use_existing_iam_role ? 0 : 1
  name  = "autospotting-${module.label.id}-task-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = module.label.tags
}

resource "aws_iam_role_policy_attachment" "autospotting_task_execution_policy_attachment" {
  count      = var.use_existing_iam_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.autospotting_task_execution[count.index].name
}



resource "aws_cloudwatch_log_group" "autospotting" {
  name              = "/fargate/autospotting-${module.label.id}/billing"
  retention_in_days = 7
}


#####
# Cloudwatch event IAM Role
#####
resource "aws_iam_role" "scheduled_task_event_role" {
  count = var.use_existing_iam_role ? 0 : 1
  name  = "${module.label.id}-task-event-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null
}

resource "aws_iam_role_policy" "scheduled_task_event_role_policy" {
  count  = var.use_existing_iam_role ? 0 : 1
  name   = "${module.label.id}-task-event-role-policy"
  role   = aws_iam_role.scheduled_task_event_role[0].id
  policy = data.aws_iam_policy_document.scheduled_task_event_role_policy_document[0].json
}

#####
# Cloudwatch event rule and target
#####
resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "${module.label.id}-rule"
  description         = ""
  schedule_expression = "rate(1 hour)"
  role_arn            = aws_iam_role.task_scheduler_role.arn


  tags = {
    Name = "${module.label.id}-rule"
  }
}

resource "aws_iam_role" "task_scheduler_role" {
  name = "${module.label.id}-cloudwatch-event-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  path = "/"
}

resource "aws_iam_role_policy" "task_scheduler_policy" {
  name = "TaskSchedulerPolicy"
  role = aws_iam_role.task_scheduler_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = "${aws_ecs_cluster.autospotting.arn}"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "ecs_task_execution_policy" {
  name = "${module.label.id}-ecs-task-execution-policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment_custom" {
  role       = aws_iam_role.task_scheduler_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}


resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {

  rule = aws_cloudwatch_event_rule.event_rule.name

  target_id  = null
  arn        = aws_ecs_cluster.autospotting.arn
  input      = null
  input_path = null
  role_arn   = var.use_existing_iam_role ? var.existing_iam_role_arn : aws_iam_role.scheduled_task_event_role[0].arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.autospotting_task_definition.arn
    task_count          = 1
    platform_version    = "LATEST"
    launch_type         = "FARGATE"
    group               = null

    network_configuration {
      subnets          = var.use_existing_subnets ? var.existing_subnets : module.vpc[0].public_subnets
      security_groups  = []
      assign_public_ip = true
    }
  }
  depends_on = [
    aws_cloudwatch_event_rule.event_rule
  ]
}

data "aws_iam_policy_document" "scheduled_task_event_role_policy_document" {
  count = var.use_existing_iam_role ? 0 : 1
  statement {
    sid    = "AllowECSRunTask"
    effect = "Allow"

    actions = ["ecs:RunTask"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowIAMPassRole"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = local.execution_role_arn == "" ? [local.task_role_arn] : [local.task_role_arn, local.execution_role_arn]
  }
}
