// Postgres Service
resource "aws_ecs_service" "postgres" {
  name            = "postgres-service"
  cluster         = "walt-prowler-cluster"
  task_definition = aws_ecs_task_definition.postgres_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service {
      client_alias {
        port     = 5432
        dns_name = "postgres-db"
      }
      port_name      = "postgres-port"
      discovery_name = "postgres"
    }

    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "service-connect-postgres"
      }
    }
  }

  enable_execute_command = true
}

// Valkey Service
resource "aws_ecs_service" "valkey" {
  name            = "valkey-service"
  cluster         = "walt-prowler-cluster"
  task_definition = aws_ecs_task_definition.valkey_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service {
      client_alias {
        port     = 6379
        dns_name = "valkey"
      }
      port_name      = "valkey-port"
      discovery_name = "valkey"
    }

    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "service-connect-valkey"
      }
    }
  }

  enable_execute_command = true
}

# API Service - This service needs to CONNECT TO postgres and valkey
resource "aws_ecs_service" "prowler_api" {
  name            = "prowler-api-service"
  cluster         = "walt-prowler-cluster"
  task_definition = aws_ecs_task_definition.prowler_api_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn

    # Register prowler-api so UI can find it
    service {
      client_alias {
        port     = 8080
        dns_name = "prowler-api"
      }
      port_name      = "prowler-api-port"
      discovery_name = "prowler-api"
    }

    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "service-connect-api"
      }
    }
  }

  enable_execute_command = true

  # Ensure Postgres and Valkey services are created first
  depends_on = [aws_ecs_service.postgres, aws_ecs_service.valkey, module.alb]
}

# UI Service - This service needs to CONNECT TO prowler-api
resource "aws_ecs_service" "prowler_ui" {
  name            = "prowler-ui-service"
  cluster         = "walt-prowler-cluster"
  task_definition = aws_ecs_task_definition.prowler_ui_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["ecs_tg"].arn
    container_name   = "prowler-ui"
    container_port   = 3000
  }

  # ADD SERVICE CONNECT - UI needs to discover prowler-api
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn

    log_configuration {
      log_driver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "service-connect-ui"
      }
    }
  }

  enable_execute_command = true

  depends_on = [module.alb, aws_ecs_service.prowler_api]
}

# Auto Scaling configuration for each service
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = {
    "postgres-service"    = aws_ecs_service.postgres.id
    "valkey-service"      = aws_ecs_service.valkey.id
    "prowler-api-service" = aws_ecs_service.prowler_api.id
    "prowler-ui-service"  = aws_ecs_service.prowler_ui.id
  }

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/walt-prowler-cluster/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  for_each = aws_appautoscaling_target.ecs_target

  name               = "cpu-auto-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}