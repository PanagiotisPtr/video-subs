resource "aws_sqs_queue" "video_processing_queue" {
  name = "video-processing-queue"
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.video_processing_queue_dead_letter.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "video_processing_queue_dead_letter" {
  name = "video-processing-queue-dead-letter"
}
