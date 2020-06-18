resource aws_ecs_cluster example-cluster {
  name = "example-ecs-cluster"
}

resource aws_launch_configuration ecs-example-launchconfig {
  name_prefix          = "ecs-launchconfig"
  image_id             = "ami-066f41adad7527ef6"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs-ec2-role.id
  security_groups      = [aws_security_group.ecs.id]
  user_data            = "#!/bin/bash\necho 'ECS_CLUSTER=${aws_ecs_cluster.example-cluster.name}' > /etc/ecs/ecs.config\nstart ecs"
  lifecycle {
    create_before_destroy = true
  }
}

resource aws_autoscaling_group ecs {
  name                      = "ecs-example-autoscaling"
  vpc_zone_identifier       = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  launch_configuration      = aws_launch_configuration.ecs-example-launchconfig.name
  min_size                  = 1
  desired_capacity          = 2
  max_size                  = 10
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "ecs-ec2-container"
    propagate_at_launch = true
  }
}

resource aws_autoscaling_policy scale_up {
  name                   = "ecs-scaleup"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.ecs.name

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_autoscaling_policy scale_down {
  name                   = "ecs-scaledown"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.ecs.name

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_cloudwatch_metric_alarm alarm-cpu-down {
  alarm_name          = "ecs-cpu-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "15"
  dimensions = {
    ClusterName = aws_ecs_cluster.example-cluster.name
  }

  alarm_description = "This metric monitors CPU utilization down"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

# CPUReservation because under high load, we'll have many containers from the other auto scaling
resource aws_cloudwatch_metric_alarm alarm-cpu-up {
  alarm_name          = "ecs-cpu-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"
  dimensions = {
    ClusterName = aws_ecs_cluster.example-cluster.name
  }

  alarm_description = "This metric monitors CPU utilization up"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

# You need this to
resource aws_appautoscaling_target ecs_target {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.example-cluster.name}/${aws_ecs_service.myapp-service.name}"
  role_arn           = aws_iam_role.ecs_autoscale.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource aws_appautoscaling_policy ecs_policy {
  name               = "autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 30
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

