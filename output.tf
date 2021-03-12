output "autospotting_function_name" {
  value = aws_lambda_function.autospotting[*].function_name
}

output "autospotting_role_name" {
  value = aws_iam_role.autospotting_role[*].name
}

