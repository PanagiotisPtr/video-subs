output "queue_url" {
  value = aws_sqs_queue.video_processing_queue.id
}

output "queue_arn" {
  value = aws_sqs_queue.video_processing_queue.arn
}
