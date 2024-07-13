resource "aws_s3_bucket" "video_bucket" {
  bucket = "video-subtitles-panagiotispetridis"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "video-subtitles-lambda-source-panagiotispetridis"
}
