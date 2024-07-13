provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./s3"
}

module "lambda" {
  source = "./lambda"
  s3_bucket_name = module.s3.bucket_name
}

module "sqs" {
  source = "./sqs"
}

module "ecs" {
  source = "./ecs"
  s3_bucket_name = module.s3.bucket_name
  sqs_queue_url = module.sqs.queue_url
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}
