provider "aws" {
  region = "us-east-1"
}

module "s3" {
  source = "./s3.tf"
}

module "lambda" {
  source = "./lambda.tf"
}

module "ecs" {
  source = "./ecs.tf"
}

module "sqs" {
  source = "./sqs.tf"
}
