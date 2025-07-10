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

  create_security_group = false

  desired_count    = 1
  cpu              = 1024
  memory           = 2048
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true

  # Attached service discovery for communicaiton among images
  service_connect_configuration = {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.cloudmap-namespace.arn
    service = {
      client_alias = {
        port     = 5432
        dns_name = "postgres-db"
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

  subnet_ids            = module.vpc.public_subnets
  security_group_ids    = [aws_security_group.ecs_task_sg.id]
  create_security_group = false

  desired_count    = 1
  cpu              = 1024
  memory           = 2048
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true

  # Attached service discovery for communicaiton among images
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

  subnet_ids            = module.vpc.public_subnets
  security_group_ids    = [aws_security_group.ecs_task_sg.id]
  create_security_group = false

  desired_count    = 1 # Worker and worker beat in the same task definition
  cpu              = 2048
  memory           = 4096 
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true


  # Attached service discovery for communicaiton among images
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

  name                   = "prowler-ui-service"
  cluster_arn            = module.ecs_cluster.arn
  task_definition_arn    = aws_ecs_task_definition.prowler_ui_task.arn
  create_task_definition = false

  subnet_ids            = module.vpc.public_subnets
  security_group_ids    = [aws_security_group.ecs_task_sg.id]
  create_security_group = false

  desired_count    = 1
  cpu              = 1024
  memory           = 2048
  assign_public_ip = true

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  enable_execute_command = true

  # Adds load balancer to the UI service 
  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ecs_tg"].arn
      container_name   = "prowler-ui"
      container_port   = 3000
    }
  }
  depends_on = [module.alb]

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

    # environment = [
    #   { name = "POSTGRES_USER", value = "prowler" },
    #   { name = "POSTGRES_PASSWORD", value = "postgres" },
    #   { name = "POSTGRES_DB", value = "prowler_db" },
    #   { name = "POSTGRES_HOST", value = "postgres-db" },
    #   { name = "POSTGRES_PORT", value = "5432" },
    #   { name = "POSTGRES_ADMIN_USER", value = "prowler_admin" },
    #   { name = "POSTGRES_ADMIN_PASSWORD", value = "postgres" }
    # ]
    environment = var.env_variables # Added for testing

    portMappings = [
      { containerPort = 5432, protocol = "tcp", name = "postgres-port" }
    ]

    # Added the HEALTH CHECK from the ENV compose file
    healthCheck = {
      command  = ["CMD-SHELL", "sh -c 'pg_isready -U prowler_admin -d prowler_db'"]
      interval = 30
      timeout  = 5
      retries  = 3
      #startPeriod = 10
    }

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

    # environment = [
    #   { name = "VALKEY_HOST", value = "valkey" },
    #   { name = "VALKEY_PORT", value = "6379" },
    #   { name = "VALKEY_DB", value = "0" }
    # ]
    environment = var.env_variables # Added for testing

    portMappings = [
      { containerPort = 6379, protocol = "tcp", name = "valkey-port" }
    ]

    # Added the HEALTH CHECK from the ENV compose file
    healthCheck = {
      command  = ["CMD-SHELL", "sh -c 'valkey-cli ping'"]
      interval = 30
      timeout  = 5
      retries  = 3
      #startPeriod = 10
    }


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
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "prowler-api"
    image = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"

    essential = true

    entryPoint = ["/home/prowler/docker-entrypoint.sh", "prod"]

    environment = var.env_variables #This is cleaner than having it as specifically

    dependencies = [{
      containerName = "postgres"
      condition     = "HEALTHY"
      },
      {
        containerName = "valkey"
        condition     = "HEALTHY"
      }

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

    # WORKER IMAGE CONFIG
    {
      name       = "worker"
      image      = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"
      essential  = false
      entryPoint = ["/home/prowler/docker-entrypoint.sh", "worker"]

      environment = var.env_variables

      dependencies = [
        {
          containerName = "valkey"
          condition     = "HEALTHY"
        },
        {
          containerName = "postgres"
          condition     = "HEALTHY"
        }
      ]

    },

    # WORKER-BEAT image config
    {
      name      = "worker-beat"
      image     = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"
      essential = false
      #entryPoint = ["/home/prowler/docker-entrypoint.sh", "beat"]
      entryPoint = ["../docker-entrypoint.sh", "beat"] # Updated to this 3/6/25 - in doc.

      environment = var.env_variables

      dependencies = [
        {
          containerName = "valkey"
          condition     = "HEALTHY"
        },
        {
          containerName = "postgres"
          condition     = "HEALTHY"
        }
      ]

      # Worker-Beat LOGS
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.prowler.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }

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
    #image     = "${module.ecr["prowlercloud/prowler-ui"].repository_url}:stable"
    image = "prowlercloud/prowler-ui:stable"
    essential = true

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

resource "aws_service_discovery_private_dns_namespace" "cloudmap-namespace" {
  name        = "prowler.local"
  description = "Private DNS namespace for ECS services"
  vpc         = module.vpc.vpc_id
}

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