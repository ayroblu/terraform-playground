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
  desired_capacity          = 1
  max_size                  = 10
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "ecs-ec2-container"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ecs-scaleup"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "ecs-scaledown"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecs.name

  lifecycle {
    create_before_destroy = true
  }
}

