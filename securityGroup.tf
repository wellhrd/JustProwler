# This is at the instance level not subnet level. 

# resource "aws_security_group" "walt_secure_GP" {
#     name                = "Security group"
#     description         = "Used for ALB and VPC and EC2 for now"
#     vpc_id              = module.vpc.vpc_id 

#     ingress {                           # changed from port 80 for prowler
#         from_port       = 3000
#         to_port         = 3000
#         protocol        = "tcp"
#         description     = "Allows HTTP traffic anywhere"
#         cidr_blocks     = ["0.0.0.0/0"]
#     }

#     ingress {
#         from_port       = 443
#         to_port         = 443
#         protocol        = "tcp"
#         description     = "Allows HTTPS traffic"
#         cidr_blocks     = ["0.0.0.0/0"]
#     }

#     egress {
#         from_port       = 0           # From port 0
#         to_port         = 0           # To port 65535 (maximum port range)
#         protocol        = "-1"        # Allow all protocols
#         cidr_blocks     = ["0.0.0.0/0"] # Allow all outbound traffic
#     }
# }

# # ALB Security Group
# resource "aws_security_group" "alb_sg" {
#   name        = "alb-sg"
#   description = "Security group for ALB"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }


#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "prowler-alb-sg"
#   }
# }


# resource "aws_security_group" "prowler_sg" {
#   name        = "prowler-sg"
#   description = "Allow HTTP traffic ..."
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = var.http_port
#     to_port     = var.http_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow inbound HTTP traffic"
#   }

#   ingress {
#     from_port = 3000
#     to_port = 3000
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow traffic to to the UI"
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "alb-sg"
#   }
# }


# ESC Security group
resource "aws_security_group" "ecs_task_sg" {
  name   = "ecs-tasks-sg"
  description = "Allow traffic among containers"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic --- to UI container"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic  -- API"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic -- POSTGRES"
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #security_groups = [ aws_security_group.ecs_task_sg.id ]
    description = "Allow all traffic -- VALKEY"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prowler-ecs-task-sg"
  }
}
