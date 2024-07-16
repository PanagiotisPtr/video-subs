terraform {
  backend "s3" {
    bucket                  = "terraform-state-video-subtitles-panagiotispetridis"
    key                     = "video-subtitles-terraform-state"
    region                  = "eu-west-1"
    shared_credentials_file = "~/.aws/credentials"
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./s3"
}

module "lambda" {
  source = "./lambda"
  sqs_queue_arn = module.sqs.queue_arn
  sqs_queue_url = module.sqs.queue_url
  s3_video_bucket_arn = module.s3.video_bucket_arn
  s3_video_bucket_id = module.s3.video_bucket_id
  s3_video_bucket_name = module.s3.video_bucket_name
  s3_lambda_bucket_name = module.s3.lambda_bucket_name
  s3_lambda_bucket_id = module.s3.lambda_bucket_id
}

module "sqs" {
  source = "./sqs"
}

module "ecs" {
  sqs_queue_url = module.sqs.queue_url
  sqs_queue_name = module.sqs.queue_name
  sqs_queue_arn = module.sqs.queue_arn
  s3_video_bucket_name = module.s3.video_bucket_name
  s3_video_bucket_arn = module.s3.video_bucket_arn
  source = "./ecs"
}
