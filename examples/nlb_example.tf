module "trafik" {
  source      = "github.com/forumone/terraform-ecs-traefik-module"
  version     = "~> 0.1"
  name        = "ecs-cluster"
  ecs_cluster = "ecs-cluster"
  suffix      = "demo.com"

}
