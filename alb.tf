# resource "aws_lb" "prowler" {
#   name               = "prowler-alb-2"
#   internal           = false
#   load_balancer_type = "application"
#   subnets            = module.vpc.public_subnets
#   security_groups    = [aws_security_group.ecs_task_sg.id]
#   enable_deletion_protection = false

#   tags = {
#     Environment = "Development"
#     Project     = "Example"
#   }
# }

# resource "aws_lb_target_group" "prowler_ui" {
#   name        = "prowler-ui"
#   port        = 3000
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id
#   target_type = "ip"

#   health_check {
#     path                = "/sign-in"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 30
#     timeout             = 10
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#   }
# }

# resource "aws_lb_listener" "http_forward" {
#   load_balancer_arn = module.alb.alb_arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = module.alb.default_target_group_arn
#   }
# }


# https://x.com/lloydtheophilus/status/1901641471524282426?s=46&t=ugYfo1ZQnaAzboVIHSIC1g >> Structure for *-*-TERRAFORM-*-*

# Using ALB from Cloud POSSE 
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = module.alb.alb_arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = module.alb.default_target_group_arn
#   }
# }



module "alb" {
  source  = "cloudposse/alb/aws"
  version = "2.2.2"

  name   = "Walts-ALB-MAC"
  vpc_id = module.vpc.vpc_id
  #security_group_ids = [aws_security_group.walt_secure_GP.id]
  security_group_ids = [aws_security_group.alb_sg.id]

  subnet_ids = module.vpc.public_subnets

  http_enabled  = var.http_enabled
  http_port     = var.http_port
  http_redirect = var.http_redirect

  cross_zone_load_balancing_enabled = var.cross_zone_load_balancing_enabled
  idle_timeout                      = var.idle_timeout

  deletion_protection_enabled       = var.deletion_protection_enabled
  deregistration_delay              = var.deregistration_delay

  health_check_path                = var.health_check_path
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  health_check_interval            = var.health_check_interval
  health_check_matcher             = var.health_check_matcher
  health_check_port                = var.health_check_port

  target_group_name                = var.target_group_name
  target_group_port                = var.target_group_port
  target_group_protocol            = var.target_group_protocol
  target_group_target_type         = var.target_group_target_type

  internal                                = false
  alb_access_logs_s3_bucket_force_destroy = var.alb_access_logs_s3_bucket_force_destroy
}


# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "9.15.0"
 
#   name                       = "local-loadbalance"
#   load_balancer_type         = "application"
#   vpc_id                     = module.vpc.vpc_id
#   subnets                    = module.vpc.public_subnets
#   enable_deletion_protection = false
 
#   security_group_ingress_rules = {
#     all_http_3000 = {
#       from_port   = 3000
#       to_port     = 3000
#       ip_protocol = "tcp"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
 
#     all_http_8080 = {
#       from_port   = 8080
#       to_port     = 8080
#       ip_protocol = "tcp"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
 
#   security_group_egress_rules = {
#     all = {
#       ip_protocol = "-1"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
 
#   listeners = {
#     ex_http_3000 = {
#       port     = 3000
#       protocol = "HTTP"
 
#       forward = {
#         target_group_key = "prowler_ui_tg"
#       }
 
#       rules = [
#         {
#           priority = 1
#           actions = [{
#             type             = "forward"
#             target_group_key = "prowler_ui_tg"
#           }]
#           conditions = [{
#             path_pattern = {
#               values = ["/", "/ui/*"]
#             }
#           }]
#         },
#         {
#           priority = 2
#           actions = [{
#             type             = "forward"
#             target_group_key = "prowler_api_tg"
#           }]
#           conditions = [{
#             path_pattern = {
#               values = ["/api/*"]
#             }
#           }]
#         }
#       ]
#     }
 
#     ex_http_8080 = {
#       port     = 8080
#       protocol = "HTTP"
 
#       forward = {
#         target_group_key = "prowler_api_tg"
#       }
#     }
#   }
 
#   target_groups = {
#     prowler_api_tg = {
#       backend_protocol = "HTTP"
#       backend_port     = 8080
#       target_type      = "ip"
 
#       health_check = {
#         enabled             = true
#         healthy_threshold   = 5
#         interval            = 30
#         matcher             = "200"
#         path                = "/"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         unhealthy_threshold = 2
#       }
#       create_attachment = false
#     }
 
#     prowler_ui_tg = {
#       backend_protocol = "HTTP"
#       backend_port     = 3000
#       target_type      = "ip"
 
#       health_check = {
#         enabled             = true
#         healthy_threshold   = 5
#         interval            = 30
#         matcher             = "200"
#         path                = "/sign-in"
#         port                = "traffic-port"
#         protocol            = "HTTP"
#         timeout             = 5
#         unhealthy_threshold = 2
#       }
#       create_attachment = false 
#     }
#   }
# }