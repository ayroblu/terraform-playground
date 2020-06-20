variable port {
  type    = number
  default = 8080
}

resource aws_cloudwatch_log_group ecs_myapp {
  name = "ecs-myapp"

  tags = {
    Environment = "ecs"
    Application = "myapp"
  }
}

resource "aws_iam_role" "task" {
  # IAM roles are global, so we need to environment name as well in the name
  name = "ecs-role-${aws_ecs_cluster.example-cluster.name}-myapp"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "myapp-task-definition" {
  family                = "myapp"
  task_role_arn         = aws_iam_role.task.arn
  container_definitions = <<EOT
[
  {
    "essential": true,
    "name": "myapp",
    "cpu": 256,
    "memory": 256,
    "image": "k8s.gcr.io/echoserver:1.4",
    "networkMode": "awsvpc",
    "portMappings": [
        {
            "containerPort": ${var.port}
        }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "ecs-myapp",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "myapp"
      }
    }
  }
]
  EOT
}

resource "aws_ecs_service" "myapp-service" {
  name            = "myapp"
  cluster         = aws_ecs_cluster.example-cluster.id
  task_definition = aws_ecs_task_definition.myapp-task-definition.arn
  desired_count   = 3
  iam_role        = aws_iam_role.ecs-service-role.arn
  depends_on = [
    aws_iam_policy_attachment.ecs-service-attach1,
    aws_lb_target_group.myapp
  ]

  load_balancer {
    target_group_arn = aws_lb_target_group.myapp.arn
    container_name   = aws_ecs_task_definition.myapp-task-definition.family
    container_port   = var.port
  }

  #lifecycle {
  #  ignore_changes = [task_definition]
  #}
}


resource aws_lb public {
  name = "public"

  idle_timeout       = 60
  load_balancer_type = "application"
  internal           = false
  enable_http2       = true

  security_groups = [aws_security_group.lb.id]
  subnets         = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
}


# Load Balancer
# The load balancer is comprised of two listeners (one for HTTP, one for HTTPS).
# The listeners are linked to target groups.  The target groups are linked to
# the ECS containers themselves within the ECS terraform configuration.
resource aws_lb_listener http_80 {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.myapp.arn
    type             = "forward"
  }
}

#resource aws_lb_listener https_443 {
#  load_balancer_arn = aws_lb.public.arn
#  port              = 443
#  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  #certificate_arn   = var.ssl_arn
#
#  default_action {
#    target_group_arn = aws_lb_target_group.ecs_bot_app_target.arn
#    type             = "forward"
#  }
#}

resource aws_lb_target_group myapp {
  name = "myapp-lb-target"

  vpc_id   = aws_vpc.main.id
  port     = var.port
  protocol = "HTTP"
  depends_on = [
    aws_lb.public
  ]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/health"
    interval            = 30
  }
}

