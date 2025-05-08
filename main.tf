module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.12.1"

  cluster_name = "walt-prowler-cluster"

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}

###########
# SERVICES #
###########

module "ecs_service_postgres" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.1"

  name                   = "postgres-service"
  cluster_arn            = module.ecs_cluster.arn
  task_definition_arn    = aws_ecs_task_definition.postgres_task.arn
  create_task_definition = false


  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.ecs_task_sg.id]

  # Addded explicit security group - explicit rule for testing else was suppose to work with > group_ids
  #  security_group_rules = {
  #   egress_all = {
  #     type        = "egress"
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   },
  #   ingress_all = {
  #     type      = "ingress"
  #     from_port = 5432
  #     to_port   = 5432
  #     protocol  = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #     description = "Postgres service port"
  #   }
  # }

  create_security_group = false


  desired_count    = 1
  cpu              = 1024
  memory           = 2048
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true


  service_connect_configuration = {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service = {
      client_alias = {
        port     = 5432
        dns_name = "posgres-db"
      }
      port_name      = "postgres-port"
      discovery_name = "postgres"
    }
  }


}

# VALKEY
module "ecs_service_valkey" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.1"

  name                   = "valkey-service"
  cluster_arn            = module.ecs_cluster.arn
  task_definition_arn    = aws_ecs_task_definition.valkey_task.arn
  create_task_definition = false

  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.ecs_task_sg.id]

  # security_group_rules = {
  #   egress_all = {
  #     type        = "egress"
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   },
  #   ingress_all = {
  #     type      = "ingress"
  #     from_port = 6379
  #     to_port   = 6379
  #     protocol  = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #     description = "VALKEY service port"
  #   }
  # }

  create_security_group = false

  desired_count    = 1
  cpu              = 1024
  memory           = 2048
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true

  service_connect_configuration = {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service = {
      client_alias = {
        port     = 6379
        dns_name = "valkey"
      }
      port_name      = "valkey-port"
      discovery_name = "valkey"
    }
  }

}

# API
module "ecs_service_api" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.1"

  name                   = "prowler-api-service"
  cluster_arn            = module.ecs_cluster.arn
  task_definition_arn    = aws_ecs_task_definition.prowler_api_task.arn
  create_task_definition = false


  subnet_ids         = module.vpc.public_subnets
  #security_group_ids = [aws_security_group.ecs_task_sg.id]

  # security_group_rules = {
  #   egress_all = {
  #     type        = "egress"
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   },
  #   ingress_all = {
  #     type      = "ingress"
  #     from_port = 8080
  #     to_port   = 8080
  #     protocol  = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #     description = "API service port"
  #   }
  # }

  create_security_group = false

  desired_count    = 1 # Worker and worker beat in the same task definition
  cpu              = 1024
  memory           = 2048
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true


  service_connect_configuration = {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service = {
      client_alias = {
        port     = 8080
        dns_name = "prowler-api"
      }
      port_name      = "prowler-api-port"
      discovery_name = "prowler-api"
    }
  }

}


# UI service 
module "ecs_service_ui" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.1"

  name                = "prowler-ui-service"
  cluster_arn         = module.ecs_cluster.arn
  task_definition_arn = aws_ecs_task_definition.prowler_ui_task.arn

  create_task_definition = false

  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.ecs_task_sg.id]

  # security_group_rules = {
  #   egress_all = {
  #     type        = "egress"
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   },
  #   ingress_all = {
  #     type      = "ingress"
  #     from_port = 3000
  #     to_port   = 3000
  #     protocol  = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #     description = "UI service port"
  #   }
  # }

  create_security_group = false

  desired_count    = 1
  cpu              = 1024
  memory           = 1024
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true

  # load_balancer = {
  #   service = {
  #     target_group_arn = module.alb.aws_lb_target_group.arn 
  #     container_name   = "prowler-ui"
  #     container_port   = 3000
  #   }
  # }
  load_balancer = {
    service = {
    target_group_arn = module.alb.default_target_group_arn
      container_name   = "prowler-ui"
      container_port   = 3000
    }
  }

  # depends_on = [ 
  #   # module.alb.target_group_arn,
  #   # module.alb.target_group_name,
  #   # module.alb.target_group_port,
  #   # module.alb.target_group_protocol,
  #   # module.alb.target_group_target_type
  #   aws_lb_listener.http

  #  ]

  service_connect_configuration = {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service = {
      client_alias = {
        port     = 3000
        dns_name = "dprowler-ui"
      }
      port_name      = "prowler-ui-port"
      discovery_name = "prowler-ui"
    }
  }

}

# Worker & Worker-beat is in the same task definition as the API

##################
# TASK Definitions
##################

#POSTGRES
resource "aws_ecs_task_definition" "postgres_task" {
  family                   = "postgres-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "postgres"
    image     = "${module.ecr["postgres"].repository_url}:16.3-alpine3.20"
    essential = true 

    environment = [
      { name = "POSTGRES_USER", value = "prowler" },
      { name = "POSTGRES_PASSWORD", value = "postgres" },
      { name = "POSTGRES_DB", value = "prowler_db" },
      { name = "POSTGRES_HOST", value = "postgres-db" },
      { name = "POSTGRES_PORT", value = "5432" },
      { name = "POSTGRES_ADMIN_USER", value = "prowler_admin" },
      { name = "POSTGRES_ADMIN_PASSWORD", value = "postgres" }
    ]

    portMappings = [
      { containerPort = 5432, protocol = "tcp", name = "postgres-port" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

}

# VALKEY - Task Definition 
resource "aws_ecs_task_definition" "valkey_task" {
  family                   = "valkey-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "valkey"
    image     = "${module.ecr["valkey/valkey"].repository_url}:7-alpine3.19"
    essential = true

    environment = [
      { name = "VALKEY_HOST", value = "valkey" },
      { name = "VALKEY_PORT", value = "6379" },
      { name = "VALKEY_DB", value = "0" }
    ]

    portMappings = [
      { containerPort = 6379, protocol = "tcp", name = "valkey-port" }
    ]


    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}


# API - task
resource "aws_ecs_task_definition" "prowler_api_task" {
  family                   = "prowler-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name       = "prowler-api"
    image      = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"
    essential  = true
    entryPoint = ["/home/prowler/docker-entrypoint.sh", "dev"]

    environment = [
      { name = "POSTGRES_HOST", value = "postgres-db" },
      { name = "POSTGRES_PORT", value = "5432" },
      { name = "POSTGRES_USER", value = "prowler" },
      { name = "POSTGRES_PASSWORD", value = "postgres" },
      { name = "POSTGRES_DB", value = "prowler_db" },
      { name = "VALKEY_HOST", value = "valkey" },
      { name = "VALKEY_PORT", value = "6379" },
      { name = "DJANGO_PORT", value = "8080" },
      { name = "DJANGO_BIND_ADDRESS", value = "0.0.0.0" },
      { name = "DJANGO_DEBUG", value = "false" },
      { name = "DJANGO_ALLOWED_HOSTS", value = "localhost,127.0.0.1,prowler-api" },
      { name = "DJANGO_SETTINGS_MODULE", value = "config.django.production" },
      { name = "DJANGO_LOGGING_LEVEL", value = "INFO" },
      { name = "DJANGO_WORKERS", value = "4" },
      { name = "DJANGO_TOKEN_SIGNING_KEY", value = "-----BEGIN PRIVATE KEY-----MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDs4e+kt7SnUJek6V5r9zMGzXCoU5qnChfPiqu+BgANyawz+MyVZPs6RCRfeo6tlCknPQtOziyXYM2I7X+qckmuzsjqp8+u+o1mw3VvUuJew5k2SQLPYwsiTzuFNVJEOgRo3hywGiGwS2iv/5nh2QAl7fq2qLqZEXQa5+/xJlQggS1CYxOJgggvLyra50QZlBvPve/AxKJ/EV/QirWTZU5lLNI8sH2iZR05vQeBsxZ0dCnGMT+vGl+cGkqrvzQzKsYbDmabMcfTYhYi78fpv6A4uharJFHayypYBjE39PwhMyyeycrNXlpm1jpq+03HgmDuDMHydk1tNwuTnEC7m7iNAgMBAAECggEAA2m48nJcJbn9SVi8bclMwKkWmbJErOnyEGEy2sTK3Of+NWx9BB0FmqAPNxn0ss8K7cANKOhDD7ZLF9E2MO4/HgfoMKtUzHRbM7MWvtEepldinnvcUMEgULD8Dk4HnqiIVjt3BdmGiTv46OpBnRWrkSBV56pUL+7msZmMZTjUZvh2ZWv0+I3gtDIjo2Zo/FiwDV7CfwRjJarRpYUj/0YyuSA4FuOUYl41WAX1I301FKMHxo3jiAYi1s7IneJ16OtPpOA34Wg5F6ebm/UO0uNe+iD4kCXKaZmxYQPh5tfB0Qa3qj1T7GNpFNyvtG7VVdauhkb8iu8X/wl6PCwbg0RCKQKBgQD9HfpnpH0lDlHMRw9KX7Vby/1fSYy1BQtlXFEIPTN/btJ/asGxLmAVwJ2HAPXWlrfSjVAH7CtVmzN7v8ojHeIHfeSgoWEu1syvnv2AMaYSo03UjFFlfc/GUxF7DUScRIhcJUPCP8jkAROz9nFvDByNjUL17Q9r43DmDiRsy0IFqQKBgQDvlJ9Uhl+Sp7gRgKYwa/IG0+I4AduAM+GzDxbm52QrMGMTjaJFLmLHBUZ/ot+pge7tZZGws8YR8ufpyMJbMqPjxhIvRRa/p1TfE3TQPW93FMsHUvxAgY3MV5MzXFPhlNAKb+akP/RcXUhetGAuZKLubtDCWa55ZQuLwj2OS+niRQKBgE7K8zUqNi6/22S8xhy/2GPgB1qPObbsABUofK0U6CAGLo6te+gc6Jo84IyzFtQbDNQFW2Fr+j1m18rw9AqkdcUhQndiZS9AfG07D+zFB86LeWHt4DS4ymIRX8Kvaak/iDcu/n3Mf0vCrhB6aetImObTj4GgrwlFvtJOmrYnO8EpAoGAIXXPXt25gWD9OyyNiVu6HKwA/zN7NYeJcRmdaDhO7B1A6R0x2Zml4AfjlbXoqOLlvLAfzd79vcoAC82nH1eOPiSOq51plPDI0LMF8IN0CtyTkn1Lj7LIXA6rF1RAvtOqzppcSvpHpZK9pcRpXnFdtBE0BMDDtl6fYzCIqlP94UUCgYEAnhXbAQMF7LQifEm34Dx8BizRMOKcqJGPvbO2+Iyt50O5X6onU2ITzSV1QHtOvAazu+B1aG9pEuBFDQ+ASxEuL9ruJElkOkb/o45TSF6KCsHd55ReTZ8AqnRjf5R+lyzPqTZCXXb8KTcRvWT4zQa3VxyT2PnaSqEcexWUy4+UXoQ=-----END PRIVATE KEY-----" },
      { name = "DJANGO_TOKEN_VERIFYING_KEY", value = "-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7OHvpLe0p1CXpOlea/czBs1wqFOapwoXz4qrvgYADcmsM/jMlWT7OkQkX3qOrZQpJz0LTs4sl2DNiO1/qnJJrs7I6qfPrvqNZsN1b1LiXsOZNkkCz2MLIk87hTVSRDoEaN4csBohsEtor/+Z4dkAJe36tqi6mRF0Gufv8SZUIIEtQmMTiYIILy8q2udEGZQbz73vwMSifxFf0Iq1k2VOZSzSPLB9omUdOb0HgbMWdHQpxjE/rxpfnBpKq780MyrGGw5mmzHH02IWIu/H6b+gOLoWqyRR2ssqWAYxN/T8ITMsnsnKzV5aZtY6avtNx4Jg7gzB8nZNbTcLk5xAu5u4jQIDAQAB-----END PUBLIC KEY-----" },
      { name = "DJANGO_SECRETS_ENCRYPTION_KEY", value = "oE/ltOhp/n1TdbHjVmzcjDPLcLA41CVI/4Rk+UB5ESc=" },
      { name = "DJANGO_BROKER_VISIBILITY_TIMEOUT", value = "86400" }
    ]

    portMappings = [
      { containerPort = 8080, protocol = "tcp", name = "prowler-api-port" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }

    },

    {
      name        = "prowler-worker"
      image       = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable" # OR -- ${module.ecr["prowlercloud/prowler-api"].repository_url}:stable
      essential   = false
      entryPoint  = ["/home/prowler/docker-entrypoint.sh", "worker"]
      environment = var.env_variables
    },

    {
      name        = "prowler-worker-beat"
      image       = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable" # OR -- ${module.ecr["prowlercloud/prowler-api"].repository_url}:stable
      essential   = false
      entryPoint  = ["/home/prowler/docker-entrypoint.sh", "beat"]
      environment = var.env_variables
    }

  ])
}

# UI - Task Definition
resource "aws_ecs_task_definition" "prowler_ui_task" {
  family                   = "prowler-ui-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "prowler-ui"
    image     = "${module.ecr["prowlercloud/prowler-ui"].repository_url}:stable"
    essential = true

    environment = [
      { name = "PROWLER_UI_VERSION", value = "stable" }, 
      { name = "AUTH_URL", value = "http://localhost:3000" }, 
      { name = "API_BASE_URL", value = "http://prowler-api:8080/api/v1" },
      { name = "NEXT_PUBLIC_API_DOCS_URL", value = "http://prowler-api:8080/api/v1/docs" },
      { name = "AUTH_TRUST_HOST", value = "true" },
      { name = "UI_PORT", value = "3000" },
      { name = "AUTH_SECRET", value = "N/c6mnaS5+SWq81+819OrzQZlmx1Vxtp/orjttJSmw8=" },
      { name = "HOST", value = "0.0.0.0" },
      { name = "DJANGO_BIND_ADDRESS", value = "0.0.0.0" }
    ]

    portMappings = [
      { containerPort = 3000, hostPort = 3000, protocol = "tcp", name = "prowler-ui-port" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.prowler.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}



# ###################### Other settings ###################################

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "prowler" {
  name              = "/ecs/prowler"
  retention_in_days = 1
  skip_destroy      = false

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
  }
}

# Task Execution Role - For pulling container images and logging
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_service_discovery_private_dns_namespace" "cloudmap-namespace" {
  name        = "walt-prowler-namespace"
  description = "Private DNS namespace for ECS services"
  vpc         = module.vpc.vpc_id
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}