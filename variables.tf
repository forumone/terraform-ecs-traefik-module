variable "vpc_id" {}
variable "nlb_arn" {}
variable "default_acm_arn" {}
variable "ecs_cluster_name" {}
variable "http_port" { default = 80 }
variable "https_port" { default = 443 }
variable "traefik_version" { default = "latest" }
variable "traefik_log_level" { default = "ERROR" }
variable "public_subnets_ipv4" {}
variable "public_subnets_ipv6" {}
variable "private_subnets_ipv4" {}
variable "private_subnets_ipv6" {}
variable "autoscaling_min" { default = 2 }
variable "autoscaling_max" { default = 4 }