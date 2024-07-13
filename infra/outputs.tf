output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}
