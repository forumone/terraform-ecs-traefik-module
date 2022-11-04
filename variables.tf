variable "name" {}
variable "suffix" {}
variable "ecs_cluster" {}
variable "http_port" { default = 8000 }
variable "https_port" { default = 8443 }
variable "traefik_version" { default = "latest" }
variable "traefik_log_level" { default = "ERROR" }
