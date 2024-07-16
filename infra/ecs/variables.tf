variable "sqs_queue_url" {
  description = "SQS URL for the video tasks queue"
  type        = string
}

variable "sqs_queue_name" {
  description = "SQS queue name for the video tasks queue"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS queue arn for the video tasks queue"
  type        = string
}

variable "s3_video_bucket_name" {
  description = "S3 bucket name for the videos"
  type        = string
}

variable "s3_video_bucket_arn" {
  description = "S3 bucket arn for the videos"
  type        = string
}
