data "archive_file" "video_processing_lambda_zip" {
  type = "zip"

  source_dir  = "../lambda/dist"
  output_path = "${path.module}/source.zip"
}

resource "aws_s3_object" "video_processing_lambda_source" {
  bucket = var.s3_lambda_bucket_id

  key    = "source.zip"
  source = data.archive_file.video_processing_lambda_zip.output_path

  etag = filemd5(data.archive_file.video_processing_lambda_zip.output_path)
}

resource "aws_cloudwatch_log_group" "s3_video_processing_trigger_lambda" {
  name = "/aws/lambda/${aws_lambda_function.s3_video_processing_trigger_lambda.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_video_trigger_lambda_policy" {
  name        = "s3_video_trigger_lambda_policy"
  description = "IAM policy for Lambda function"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource  = "${aws_cloudwatch_log_group.s3_video_processing_trigger_lambda.arn}:*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "sqs:SendMessage"
        ],
        Resource  = var.sqs_queue_arn
      },
      {
        Effect    = "Allow",
        Action    = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource  = "${var.s3_video_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.s3_video_trigger_lambda_policy.arn
}

resource "aws_lambda_function" "s3_video_processing_trigger_lambda" {
  function_name = "s3-video-processing-trigger-lambda"
  s3_bucket = var.s3_lambda_bucket_id
  s3_key    = aws_s3_object.video_processing_lambda_source.key

  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60

  environment {
    variables = {
      SQS_QUEUE_URL = var.sqs_queue_url
    }
  }
}

resource "aws_lambda_permission" "allow_s3_event" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_video_processing_trigger_lambda.function_name
  principal     = "s3.amazonaws.com"
  
  source_arn = var.s3_video_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_video_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_video_processing_trigger_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input_videos/"
  }

  depends_on = [aws_lambda_permission.allow_s3_event]
}
