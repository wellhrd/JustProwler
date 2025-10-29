module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "3.5.0"

  name = "walt-prowler-cluster"

  container_insights = true

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 100
      base              = 20
    }
  ]
}

###########
# SERVICES #
###########

# ECS Services have been moved to ecs_services.tf

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
    name = "postgres"
    #image     = "${module.ecr["postgres"].repository_url}:16.3-alpine3.20"
    image     = "prowlercloud/prowler-api:8ebefb8" # TEMPORARY OVERRIDE FOR TESTING
    essential = true

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
    name = "prowler-api"
    #image = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"
    image = "prowlercloud/prowler-api:8ebefb8" # TEMPORARY OVERRIDE FOR TESTING

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
      name = "worker"
      #image      = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"
      image      = "prowlercloud/prowler-api:8ebefb8" # TEMPORARY OVERRIDE FOR TESTING
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
      name = "worker-beat"
      #image     = "${module.ecr["prowlercloud/prowler-api"].repository_url}:stable"
      image      = "prowlercloud/prowler-api:8ebefb8" # TEMPORARY OVERRIDE FOR TESTING
      essential  = false
      entryPoint = ["../docker-entrypoint.sh", "beat"]

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
    image     = "prowlercloud/prowler-ui:stable"
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