provider "aws" {
  region = var.region
}

# Create a Security Group for the ECS instances
resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-sg-"
  description = "Security group for ECS instances"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a Launch Template for ECS instances
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "ecs-"
  image_id      = data.aws_ami.amzn2.id
  instance_type = "g4dn.xlarge"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }

  iam_instance_profile {
    name = var.ecs_instance_profile_name
  }

  user_data = base64encode(data.template_file.ecs_user_data.rendered)
}

# ECS Cluster
resource "aws_ecs_cluster" "video_processing_cluster" {
  name = "video-processing-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "video_processing_task" {
  family                   = "video-processing-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "1024"
  memory                   = "2048"

  container_definitions = jsonencode([{
    name      = "video-processor"
    image     = var.ecr_repository_url
    essential = true
    memory    = 2048
    cpu       = 1024
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    environment = [
      {
        name  = "SQS_QUEUE_URL"
        value = var.sqs_queue_url
      },
      {
        name  = "AWS_REGION"
        value = var.region
      }
    ]
  }])
}

# ECS Service
resource "aws_ecs_service" "video_processing_service" {
  name            = "video-processing-service"
  cluster         = aws_ecs_cluster.video_processing_cluster.id
  task_definition = aws_ecs_task_definition.video_processing_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity     = 0
  max_size             = 2
  min_size             = 0
  vpc_zone_identifier  = var.subnets
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}

# CloudWatch Alarms for scaling policies
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "ecs-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "Scale up ECS instances when there are more than 10 messages in the queue"
  dimensions = {
    QueueName = aws_sqs_queue.video_processing_queue.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "ecs-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Scale down ECS instances when there are less than 1 messages in the queue"
  dimensions = {
    QueueName = aws_sqs_queue.video_processing_queue.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
}

# SQS Queue (example resource, if not already created)
resource "aws_sqs_queue" "video_processing_queue" {
  name = "video-processing-queue"
}

# User data script for ECS instances
data "template_file" "ecs_user_data" {
  template = file("${path.module}/ecs_user_data.sh")

  vars = {
    cluster_name = aws_ecs_cluster.video_processing_cluster.name
  }
}

variable "region" {
  description = "The AWS region to deploy resources in"
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "The VPC ID to deploy the ECS cluster in"
}

variable "subnets" {
  description = "The list of subnets to deploy the ECS cluster in"
  type        = list(string)
}

variable "ecs_instance_profile_name" {
  description = "The name of the IAM instance profile for ECS instances"
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository"
}

variable "sqs_queue_url" {
  description = "The URL of the SQS queue"
}
