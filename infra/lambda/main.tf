resource "aws_lambda_function" "video_processing_lambda" {
  filename      = "s3-trigger-lambda.zip"
  function_name = "video_processing_lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 300

  environment {
    variables = {
      SQS_QUEUE_URL = module.sqs.queue_url
      S3_BUCKET_NAME = var.s3_bucket_name
    }
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.video_processing_lambda.function_name
}
