resource "aws_s3_bucket" "video_processing" {
  bucket = "video-processing-bucket"
  
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire_old_versions"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_object" "input_videos" {
  bucket = aws_s3_bucket.video_processing.bucket
  key    = "input_videos/"
}

resource "aws_s3_bucket_object" "output_videos" {
  bucket = aws_s3_bucket.video_processing.bucket
  key    = "output_videos/"
}

