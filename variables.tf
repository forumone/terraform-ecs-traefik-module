variable "name" {}
variable "vpc_id" {}
variable "nlb_id" {}
variable "suffix" {}
variable "default_acm" {}
variable "ecs_cluster_id" {}
variable "http_port" { default = 8000 }
variable "https_port" { default = 8443 }
variable "traefik_version" { default = "latest" }
variable "traefik_log_level" { default = "ERROR" }
variable "public_subnets_ipv4" {}
variable "public_subnets_ipv6" {}
