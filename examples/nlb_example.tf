module "traefik" {
  source               = "github.com/forumone/terraform-ecs-traefik-module?ref=v1.0.0"
  vpc_id               = module.vpc.vpc_id
  public_subnets_ipv4  = module.vpc.public_subnets_cidr_blocks
  public_subnets_ipv6  = module.vpc.public_subnets_ipv6_cidr_blocks
  private_subnets_ipv4 = module.vpc.private_subnets_cidr_blocks
  private_subnets_ipv6 = module.vpc.private_subnets_ipv6_cidr_blocks
  nlb_arn              = module.nlb.nlb_arn
  ecs_cluster_name     = module.ecs_cluster_name
  default_acm_arn      = module.acm.default.arn
  autoscaling_min      = 1 # default = 2
  autoscaling_max      = 2 # default = 4
}
