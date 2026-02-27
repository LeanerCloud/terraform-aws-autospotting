
locals {
  deploy_fargate     = var.deploy_fargate
  task_role_arn      = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : (local.deploy_fargate ? aws_iam_role.autospotting_task_execution[0].arn : "")
  execution_role_arn = var.use_existing_iam_role ? data.aws_arn.role_arn[0].arn : (local.deploy_fargate ? aws_iam_role.autospotting_task_execution[0].arn : "")
}

data "aws_availability_zones" "available" {
  count = local.deploy_fargate ? 1 : 0
  state = "available"
}
data "aws_region" "current" {}

module "vpc" {
  count   = local.deploy_fargate && !var.use_existing_subnets ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0, < 7.0"

  name = "autospotting-${module.label.id}"

  cidr = "192.168.0.0/24"

  azs            = [data.aws_availability_zones.available[0].names[0], data.aws_availability_zones.available[0].names[1]]
  public_subnets = ["192.168.0.0/25", "192.168.0.128/25"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Egress-only security group for Fargate tasks
resource "aws_security_group" "fargate" {
  count       = local.deploy_fargate && !var.use_existing_subnets ? 1 : 0
  name        = "autospotting-fargate-${module.label.id}"
  description = "Egress-only HTTPS for Fargate billing tasks"
  vpc_id      = module.vpc[0].vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  tags = module.label.tags
}

resource "aws_ecs_cluster" "autospotting" {
  count = local.deploy_fargate ? 1 : 0
  name  = "autospotting-${module.label.id}"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  count        = local.deploy_fargate ? 1 : 0
  cluster_name = aws_ecs_cluster.autospotting[0].name

  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

# ECS service-linked role
resource "aws_iam_service_linked_role" "ecs" {
  count            = local.deploy_fargate && var.create_service_linked_roles ? 1 : 0
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_ecs_task_definition" "autospotting_task_definition" {
  count                    = local.deploy_fargate ? 1 : 0
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
        awslogs-group         = aws_cloudwatch_log_group.autospotting[0].name
        awslogs-region        = data.aws_region.current.id
        awslogs-stream-prefix = "autospotting-billing"
      }
    }
  }])

  tags = module.label.tags

  depends_on = [aws_iam_service_linked_role.ecs]
}

resource "aws_iam_role" "autospotting_task_execution" {
  count = !var.use_existing_iam_role && local.deploy_fargate ? 1 : 0
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
  count      = !var.use_existing_iam_role && local.deploy_fargate ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.autospotting_task_execution[0].name
}

resource "aws_cloudwatch_log_group" "autospotting" {
  count             = local.deploy_fargate ? 1 : 0
  name              = "/fargate/autospotting-${module.label.id}/billing"
  retention_in_days = var.log_retention_days
}

#####
# Cloudwatch event IAM Role
#####
resource "aws_iam_role" "scheduled_task_event_role" {
  count = !var.use_existing_iam_role && local.deploy_fargate ? 1 : 0
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
  count  = !var.use_existing_iam_role && local.deploy_fargate ? 1 : 0
  name   = "${module.label.id}-task-event-role-policy"
  role   = aws_iam_role.scheduled_task_event_role[0].id
  policy = data.aws_iam_policy_document.scheduled_task_event_role_policy_document[0].json
}

#####
# Cloudwatch event rule and target
#####
resource "aws_cloudwatch_event_rule" "event_rule" {
  count               = local.deploy_fargate ? 1 : 0
  name                = "${module.label.id}-rule"
  description         = ""
  schedule_expression = "rate(1 hour)"

  tags = {
    Name = "${module.label.id}-rule"
  }
}

resource "aws_iam_role" "task_scheduler_role" {
  count = local.deploy_fargate ? 1 : 0
  name  = "${module.label.id}-cloudwatch-event-role"

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
  count = local.deploy_fargate ? 1 : 0
  name  = "TaskSchedulerPolicy"
  role  = aws_iam_role.task_scheduler_role[0].id

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
            "ecs:cluster" = aws_ecs_cluster.autospotting[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  count = local.deploy_fargate ? 1 : 0
  name  = "${module.label.id}-ecs-task-execution-policy"
  path  = "/"
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
  count      = local.deploy_fargate ? 1 : 0
  role       = aws_iam_role.task_scheduler_role[0].name
  policy_arn = aws_iam_policy.ecs_task_execution_policy[0].arn
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  count = local.deploy_fargate ? 1 : 0

  rule = aws_cloudwatch_event_rule.event_rule[0].name

  target_id  = null
  arn        = aws_ecs_cluster.autospotting[0].arn
  input      = null
  input_path = null
  role_arn   = var.use_existing_iam_role ? var.existing_iam_role_arn : aws_iam_role.scheduled_task_event_role[0].arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.autospotting_task_definition[0].arn
    task_count          = 1
    platform_version    = "LATEST"
    launch_type         = "FARGATE"
    group               = null

    network_configuration {
      subnets          = var.use_existing_subnets ? var.existing_subnets : module.vpc[0].public_subnets
      security_groups  = var.use_existing_subnets ? [] : [aws_security_group.fargate[0].id]
      assign_public_ip = true
    }
  }
  depends_on = [
    aws_cloudwatch_event_rule.event_rule
  ]
}

data "aws_iam_policy_document" "scheduled_task_event_role_policy_document" {
  count = !var.use_existing_iam_role && local.deploy_fargate ? 1 : 0
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
