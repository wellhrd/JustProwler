module "alb" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "9.15.0"
  security_groups = [aws_security_group.ecs_task_sg.id]

  name                       = "New-Prowler-ALB"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ecs_tg"  # Default forward to UI
      }

      rules = [
        {
          priority = 1
          actions = [{
            type             = "forward"
            target_group_key = "api_tg"  # Route /api/* to API
          }]
          conditions = [{
            path_pattern = {
              values = ["/api/*"]
            }
          }]
        },
        {
          priority = 2
          actions = [{
            type             = "forward"
            target_group_key = "ecs_tg"  # Route everything else to UI
          }]
          conditions = [{
            path_pattern = {
              values = ["/*"]
            }
          }]
        }
      ]
    }
  }

  target_groups = {
    # UI Target Group
    ecs_tg = {
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200-499"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      create_attachment = false
    }
    
    # API Target Group (NEW)
    api_tg = {
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200-499"
        path                = "/api/*"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 10
        unhealthy_threshold = 2
      }
      create_attachment = false
    }
  }
}