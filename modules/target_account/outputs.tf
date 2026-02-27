output "execution_role_arn" {
  description = "ARN of the execution role for AutoSpotting to assume"
  value       = aws_iam_role.execution_role.arn
}

output "eventbridge_role_arn" {
  description = "ARN of the EventBridge cross-account forwarding role"
  value       = aws_iam_role.eventbridge_role.arn
}
