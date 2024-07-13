output "s3_bucket_name" {
  value = aws_s3_bucket.video_processing.bucket
}

output "sqs_queue_url" {
  value = aws_sqs_queue.video_processing_queue.url
}

output "lambda_function_name" {
  value = aws_lambda_function.s3_trigger.function_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.video_processing_cluster.name
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.video_processing_task.arn
}

