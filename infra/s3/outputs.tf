output "video_bucket_name" {
  value = aws_s3_bucket.video_bucket.bucket
}

output "video_bucket_arn" {
  value = aws_s3_bucket.video_bucket.arn
}

output "video_bucket_id" {
  value = aws_s3_bucket.video_bucket.id
}

output "lambda_bucket_name" {
  value = aws_s3_bucket.lambda_bucket.bucket
}

output "lambda_bucket_id" {
  value = aws_s3_bucket.lambda_bucket.id
}
