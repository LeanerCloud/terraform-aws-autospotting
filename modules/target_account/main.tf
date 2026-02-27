data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM execution role that the main account Lambda assumes into this account
resource "aws_iam_role" "execution_role" {
  name = "${var.name_prefix}-Execution-Role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.autospotting_lambda_role_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "execution_policy" {
  name = "${var.name_prefix}-execution-policy"
  role = aws_iam_role.execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AutoSpottingPermissions"
        Effect = "Allow"
        Action = [
          "autoscaling:AttachInstances",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:DetachInstances",
          "autoscaling:ResumeProcesses",
          "autoscaling:SetInstanceProtection",
          "autoscaling:SuspendProcesses",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "cloudformation:Describe*",
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "ec2:AssociateAddress",
          "ec2:AttachVolume",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteTags",
          "ec2:DescribeAddresses",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:DisassociateAddress",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ecs:DeregisterContainerInstance",
          "ecs:DescribeContainerInstances",
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:UpdateContainerInstancesState",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "iam:CreateServiceLinkedRole",
          "iam:PassRole",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:GetParameterHistory",
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge cross-account role for forwarding events to the main account
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.name_prefix}-eventbridge-role"
  path = "/events/"

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
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${var.name_prefix}-eventbridge-put-events"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "events:PutEvents"
        Resource = "arn:aws:events:${var.main_region}:${var.main_account_id}:event-bus/default"
      }
    ]
  })
}
