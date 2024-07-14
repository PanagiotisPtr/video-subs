resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "video-subs-main-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "video-subs-main-subnet"
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
}

resource "aws_launch_template" "ecs" {
  name          = "ecs-launch-template"
  image_id      = data.aws_ami.ami.id
  instance_type = "g4dn.xlarge"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_autoscaling_group" "ecs" {
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.main.id]

  min_size = 0
  max_size = 2
  desired_capacity = 0

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_ecs_service" "main" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 0
  launch_type     = "EC2"

  network_configuration {
    subnets          = [aws_subnet.main.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  depends_on = [aws_autoscaling_group.ecs]
}

resource "aws_ecs_task_definition" "main" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "4096"
  memory                   = "16384"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "video-processor"
      image     = "764060347059.dkr.ecr.eu-west-1.amazonaws.com/video-processing-task:latest"
      cpu       = 4096
      memory    = 16384
      essential = true
      command   = ["python3", "video_processor.py"]
      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = var.sqs_queue_url
        },
        {
          name  = "S3_BUCKET_NAME"
          value = var.s3_video_bucket_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "eu-west-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "ScaleUpAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "ScaleDownAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs.name
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/video-processing-task"
  retention_in_days = 7

  tags = {
    Name = "ecs-log-group"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "ecsTaskExecutionPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        Resource  = "${aws_cloudwatch_log_group.ecs_log_group.arn}:*"
      }
    ]
  })
}
