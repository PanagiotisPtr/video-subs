variable "sqs_queue_arn" {
  description = "SQS arn for the video tasks queue"
  type        = string
}

variable "sqs_queue_url" {
  description = "SQS URL for the video tasks queue"
  type        = string
}

variable "s3_video_bucket_arn" {
  description = "S3 bucket arn for the videos"
  type        = string
}

variable "s3_video_bucket_name" {
  description = "S3 bucket name for the videos"
  type        = string
}

variable "s3_video_bucket_id" {
  description = "S3 bucket id for the videos"
  type        = string
}

variable "s3_lambda_bucket_name" {
  description = "S3 bucket name with s3 trigger lambda source code"
  type        = string
}

variable "s3_lambda_bucket_id" {
  description = "S3 id name with s3 trigger lambda source code"
  type        = string
}
