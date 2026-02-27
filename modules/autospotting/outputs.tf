output "function_name" {
  value = aws_lambda_function.autospotting.function_name
}

output "arn" {
  value = aws_lambda_function.autospotting.arn
}


output "sqs_queue_arn" {
  value = aws_sqs_queue.autospotting_fifo_queue.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.autospotting_fifo_queue.url
}
