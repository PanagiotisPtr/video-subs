resource "aws_ecs_cluster" "video_processing_cluster" {
  name = "video-processing-cluster"
}

resource "aws_ecs_task_definition" "video_processing_task" {
  family                   = "video-processing-task"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "4096" 
  memory                   = "8192"

  container_definitions = jsonencode([
    {
      name      = "video-processor"
      image     = "your-video-processor-image-url"
      cpu       = 1024
      memory    = 2048
      essential = true
      command   = ["python3", "video_processor.py"]
      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = module.sqs.queue_url
        },
        {
          name  = "S3_BUCKET_NAME"
          value = var.s3_bucket_name
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "video_processing_service" {
  name            = "video-processing-service"
  cluster         = aws_ecs_cluster.video_processing_cluster.id
  task_definition = aws_ecs_task_definition.video_processing_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = ["subnet-12345678", "subnet-87654321"]
    assign_public_ip = true
    security_groups  = ["sg-abcdef12"]
  }
}

output "cluster_id" {
  value = aws_ecs_cluster.video_processing_cluster.id
}

