resource "aws_s3_bucket" "video_bucket" {
  bucket = "video-subtitles"
  acl    = "private"
  
  lifecycle {
    prevent_destroy = false
  }
  
  versioning {
    enabled = true
  }

  event_notification {
    bucket = aws_s3_bucket.video_bucket.id

    lambda_function {
      lambda_function_arn = aws_lambda_function.video_processing_lambda.arn
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = "input_videos/"
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.video_bucket.bucket
}
