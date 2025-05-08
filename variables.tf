# EC2 Variables 
variable "name" {
  description = "This is the name of my first instance"
  type        = string
  default     = "Walt-Ec2"
}

# VPC Variables
variable "vpc_name" {
  description = "This is where all of my Ec2 and RDS is stored"
  type        = string
  default     = "Walt-VPC"
}

variable "vpc_id" {
  description = "The ID which shows where the Virtual Private CLoud is provided"
  type        = string
  default     = ""
}

variable "s3_name" {
  description = "The name of the bucket"
  type        = string
  default     = "walt-s3"
}

variable "bucket_id" {
  type    = string
  default = ""
}

variable "EnvironmentName" {
  type    = string
  default = "development"
}

variable "subnet_ids" {
  type    = list(string)
  default = ["172.30.3.0/28", "172.30.4.0/28"]
}

# ------ ECR Variables ------
variable "ecr_repositories" {
  description = "List of ECR repository names"
  type        = list(string)
  default = [
    "prowlercloud/prowler-ui",
    "valkey/valkey",
    "postgres",
    "prowlercloud/prowler-api",
    "prowler-worker",
    "prowler-worker-beat"
  ]
}

variable "repository_image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE`. Defaults to `IMMUTABLE`"
  type        = string
  default     = "IMMUTABLE"
}

# Added for ALB Cloud Posse
variable "http_port" {
  type        = number
  default     = 80 #Changed to 80 for the ALB (will route to 3000 on the container)
  description = "The port for the HTTP listener"
}

variable "http_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP listener"
}

variable "http_redirect" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable HTTP redirect to HTTPS"
}

variable "cross_zone_load_balancing_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable cross zone load balancing"
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle"
}

variable "deletion_protection_enabled" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable deletion protection for ALB"
}

variable "deregistration_delay" {
  type        = number
  default     = 15
  description = "The amount of time to wait in seconds before changing the state of a deregistering target to unused"
}

variable "health_check_path" {
  type        = string
  default     = "/api/v1/health"
  description = "The destination for the health check request"
}

variable "health_check_port" {
  type        = string
  default     = "traffic-port"
  description = "The port to use for the healthcheck"
}

variable "health_check_protocol" {
  type        = string
  default     = "HTTP"
  description = "The protocol to use for the healthcheck. If not specified, same as the traffic protocol"
}

variable "health_check_timeout" {
  type        = number
  default     = 10
  description = "The amount of time to wait in seconds before failing a health check request"
}

variable "health_check_healthy_threshold" {
  type        = number
  default     = 5
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  default     = 2
  description = "The number of consecutive health check failures required before considering the target unhealthy"
}

variable "health_check_interval" {
  type        = number
  default     = 30
  description = "The duration in seconds in between health checks"
}

variable "health_check_matcher" {
  type        = string
  default     = "200-399"
  description = "The HTTP response codes to indicate a healthy check"
}

variable "target_group_port" {
  type        = number
  default     = 3000
  description = "The port for the default target group"
}

variable "target_group_protocol" {
  type        = string
  default     = "HTTP"
  description = "The protocol for the default target group HTTP or HTTPS"
}

variable "target_group_name" {
  type        = string
  default     = "prowler-ui-service"
  description = "The name for the default target group, uses a module label name if left empty"
}

variable "target_group_target_type" {
  type        = string
  default     = "ip" # Important for FARGATE
  description = "The type (`instance`, `ip` or `lambda`) of targets that can be registered with the target group"
}

variable "alb_access_logs_s3_bucket_force_destroy" {
  type        = bool
  default     = true
  description = "A boolean that indicates all objects should be deleted from the ALB access logs S3 bucket so that the bucket can be destroyed without error"
}


# ECS VARIABLES
variable "enable_autoscaling" {
  description = "Flag to enable or disable autoscaling for Fargate services"
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "The minimum number of tasks for autoscaling of Fargate services"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "The maximum number of tasks for autoscaling of Fargate services"
  type        = number
  default     = 10
}




# Var just for wrker and beat
variable "env_variables" {
  description = "The base domain for your infrastructure"
  type        = list(object({
    name = string
    value = string
  }))
  default = [
    { name = "PROWLER_UI_VERSION",              value = "stable" },
    { name = "AUTH_URL",                        value = "http://prow:3000" },
    { name = "API_BASE_URL",                    value = "http://prowler-api:8080/api/v1" },
    { name = "NEXT_PUBLIC_API_DOCS_URL",        value = "http://prowler-api:8080/api/v1/docs" },
    { name = "AUTH_TRUST_HOST",                 value = "true" },
    { name = "UI_PORT",                         value = "3000" },
    { name = "AUTH_SECRET",                     value = "N/c6mnaS5+SWq81+819OrzQZlmx1Vxtp/orjttJSmw8=" },
 
    { name = "PROWLER_API_VERSION",             value = "stable" },
    { name = "POSTGRES_HOST",                   value = "postgres-service" },
    { name = "POSTGRES_PORT",                   value = "5432" },
    { name = "POSTGRES_ADMIN_USER",             value = "prowler_admin" },
    { name = "POSTGRES_ADMIN_PASSWORD",         value = "postgres" },
    { name = "POSTGRES_USER",                   value = "prowler" },
    { name = "POSTGRES_PASSWORD",               value = "postgres" },
    { name = "POSTGRES_DB",                     value = "prowler_db" },
 
    { name = "VALKEY_HOST",                     value = "valkey-service" },
    { name = "VALKEY_PORT",                     value = "6379" },
    { name = "VALKEY_DB",                       value = "0" },
 
    { name = "DJANGO_TMP_OUTPUT_DIRECTORY",     value = "/tmp/prowler_api_output" },
    { name = "DJANGO_FINDINGS_BATCH_SIZE",      value = "1000" },
    { name = "DJANGO_OUTPUT_S3_AWS_ACCESS_KEY_ID",      value = "" },
    { name = "DJANGO_OUTPUT_S3_AWS_SECRET_ACCESS_KEY",   value = "" },
    { name = "DJANGO_OUTPUT_S3_AWS_SESSION_TOKEN",       value = "" },
    { name = "DJANGO_OUTPUT_S3_AWS_DEFAULT_REGION",      value = "" },
    { name = "DJANGO_OUTPUT_S3_AWS_OUTPUT_BUCKET",       value = "" },
 
    { name = "DJANGO_ALLOWED_HOSTS",            value = "localhost,127.0.0.1,prowler-api" },
    { name = "DJANGO_BIND_ADDRESS",             value = "0.0.0.0" },
    { name = "DJANGO_PORT",                     value = "8080" },
    { name = "DJANGO_DEBUG",                    value = "False" },
    { name = "DJANGO_SETTINGS_MODULE",          value = "config.django.production" },
    { name = "DJANGO_LOGGING_FORMATTER",        value = "human_readable" },
    { name = "DJANGO_LOGGING_LEVEL",            value = "INFO" },
    { name = "DJANGO_WORKERS",                  value = "4" },
    { name = "DJANGO_ACCESS_TOKEN_LIFETIME",    value = "30" },
    { name = "DJANGO_REFRESH_TOKEN_LIFETIME",   value = "1440" },
    { name = "DJANGO_CACHE_MAX_AGE",            value = "3600" },
    { name = "DJANGO_STALE_WHILE_REVALIDATE",   value = "60" },
    { name = "DJANGO_MANAGE_DB_PARTITIONS",     value = "True" },
 
    { name = "DJANGO_TOKEN_SIGNING_KEY", value = <<-EOT
        -----BEGIN PRIVATE KEY-----
        MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDs4e+kt7SnUJek
        6V5r9zMGzXCoU5qnChfPiqu+BgANyawz+MyVZPs6RCRfeo6tlCknPQtOziyXYM2I
        7X+qckmuzsjqp8+u+o1mw3VvUuJew5k2SQLPYwsiTzuFNVJEOgRo3hywGiGwS2iv
        /5nh2QAl7fq2qLqZEXQa5+/xJlQggS1CYxOJgggvLyra50QZlBvPve/AxKJ/EV/Q
        irWTZU5lLNI8sH2iZR05vQeBsxZ0dCnGMT+vGl+cGkqrvzQzKsYbDmabMcfTYhYi
        78fpv6A4uharJFHayypYBjE39PwhMyyeycrNXlpm1jpq+03HgmDuDMHydk1tNwuT
        nEC7m7iNAgMBAAECggEAA2m48nJcJbn9SVi8bclMwKkWmbJErOnyEGEy2sTK3Of+
        NWx9BB0FmqAPNxn0ss8K7cANKOhDD7ZLF9E2MO4/HgfoMKtUzHRbM7MWvtEepldi
        nnvcUMEgULD8Dk4HnqiIVjt3BdmGiTv46OpBnRWrkSBV56pUL+7msZmMZTjUZvh2
        ZWv0+I3gtDIjo2Zo/FiwDV7CfwRjJarRpYUj/0YyuSA4FuOUYl41WAX1I301FKMH
        xo3jiAYi1s7IneJ16OtPpOA34Wg5F6ebm/UO0uNe+iD4kCXKaZmxYQPh5tfB0Qa3
        qj1T7GNpFNyvtG7VVdauhkb8iu8X/wl6PCwbg0RCKQKBgQD9HfpnpH0lDlHMRw9K
        X7Vby/1fSYy1BQtlXFEIPTN/btJ/asGxLmAVwJ2HAPXWlrfSjVAH7CtVmzN7v8oj
        HeIHfeSgoWEu1syvnv2AMaYSo03UjFFlfc/GUxF7DUScRIhcJUPCP8jkAROz9nFv
        DByNjUL17Q9r43DmDiRsy0IFqQKBgQDvlJ9Uhl+Sp7gRgKYwa/IG0+I4AduAM+Gz
        Dxbm52QrMGMTjaJFLmLHBUZ/ot+pge7tZZGws8YR8ufpyMJbMqPjxhIvRRa/p1Tf
        E3TQPW93FMsHUvxAgY3MV5MzXFPhlNAKb+akP/RcXUhetGAuZKLubtDCWa55ZQuL
        wj2OS+niRQKBgE7K8zUqNi6/22S8xhy/2GPgB1qPObbsABUofK0U6CAGLo6te+gc
        6Jo84IyzFtQbDNQFW2Fr+j1m18rw9AqkdcUhQndiZS9AfG07D+zFB86LeWHt4DS4
        ymIRX8Kvaak/iDcu/n3Mf0vCrhB6aetImObTj4GgrwlFvtJOmrYnO8EpAoGAIXXP
        Xt25gWD9OyyNiVu6HKwA/zN7NYeJcRmdaDhO7B1A6R0x2Zml4AfjlbXoqOLlvLAf
        zd79vcoAC82nH1eOPiSOq51plPDI0LMF8IN0CtyTkn1Lj7LIXA6rF1RAvtOqzppc
        SvpHpZK9pcRpXnFdtBE0BMDDtl6fYzCIqlP94UUCgYEAnhXbAQMF7LQifEm34Dx8
        BizRMOKcqJGPvbO2+Iyt50O5X6onU2ITzSV1QHtOvAazu+B1aG9pEuBFDQ+ASxEu
        L9ruJElkOkb/o45TSF6KCsHd55ReTZ8AqnRjf5R+lyzPqTZCXXb8KTcRvWT4zQa3
        VxyT2PnaSqEcexWUy4+UXoQ=
        -----END PRIVATE KEY-----
        EOT
    },
 
    { name = "DJANGO_TOKEN_VERIFYING_KEY", value = <<-EOT
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7OHvpLe0p1CXpOlea/cz
        Bs1wqFOapwoXz4qrvgYADcmsM/jMlWT7OkQkX3qOrZQpJz0LTs4sl2DNiO1/qnJJ
        rs7I6qfPrvqNZsN1b1LiXsOZNkkCz2MLIk87hTVSRDoEaN4csBohsEtor/+Z4dkA
        Je36tqi6mRF0Gufv8SZUIIEtQmMTiYIILy8q2udEGZQbz73vwMSifxFf0Iq1k2VO
        ZSzSPLB9omUdOb0HgbMWdHQpxjE/rxpfnBpKq780MyrGGw5mmzHH02IWIu/H6b+g
        OLoWqyRR2ssqWAYxN/T8ITMsnsnKzV5aZtY6avtNx4Jg7gzB8nZNbTcLk5xAu5u4
        jQIDAQAB
        -----END PUBLIC KEY-----
        EOT
    },
 
    { name = "DJANGO_SECRETS_ENCRYPTION_KEY", value = "oE/ltOhp/n1TdbHjVmzcjDPLcLA41CVI/4Rk+UB5ESc=" },
    { name = "DJANGO_BROKER_VISIBILITY_TIMEOUT", value = "86400" },
    { name = "DJANGO_SENTRY_DSN", value = "" },
 
    { name = "SENTRY_ENVIRONMENT", value = "local" },
    { name = "SENTRY_RELEASE", value = "local" },
 
    { name = "NEXT_PUBLIC_PROWLER_RELEASE_VERSION", value = "v5.6.0" },
 
    # { name = "SOCIAL_GOOGLE_OAUTH_CALLBACK_URL", value = "${AUTH_URL}/api/auth/callback/google" },
    # { name = "SOCIAL_GOOGLE_OAUTH_CLIENT_ID", value = "" },
    # { name = "SOCIAL_GOOGLE_OAUTH_CLIENT_SECRET", value = "" },
 
    # { name = "SOCIAL_GITHUB_OAUTH_CALLBACK_URL", value = "${AUTH_URL}/api/auth/callback/github" },
    # { name = "SOCIAL_GITHUB_OAUTH_CLIENT_ID", value = "" },
    # { name = "SOCIAL_GITHUB_OAUTH_CLIENT_SECRET", value = "" }
  ]
}