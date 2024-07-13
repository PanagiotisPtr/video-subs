variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "video-processing-cluster"
}
