# Terraform AWS ECS Traefik Module
Terraform Module for Deploying Traefik Application Proxy Containers in ECS behind a Network Load Balancer.
Forwards all HTTP Traffic to HTTPS.

## Requirements

- ECS cluster
- Network Load Balancer
- VPC
- Valid AWS ACM Certificate

## Usage
```hcl
module "traefik" {
  source               = "github.com/forumone/terraform-ecs-traefik-module?ref=v1.0.0"
  vpc_id               = module.vpc.vpc_id
  public_subnets_ipv4  = module.vpc.public_subnets_cidr_blocks
  public_subnets_ipv6  = module.vpc.public_subnets_ipv6_cidr_blocks
  private_subnets_ipv4 = module.vpc.private_subnets_cidr_blocks
  private_subnets_ipv6 = module.vpc.private_subnets_ipv6_cidr_blocks
  nlb_arn              = module.nlb.nlb_arn
  ecs_cluster_name     = module.ecs_cluster_name
  default_acm_arn          = module.acm.default.arn
}
```

## Examples

- [ECS Cluster w/ NLB and ACM](https://github.com/forumone/terraform-ecs-traefik-module/examples/nlb_example.tf)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [Traefik Application Proxy](https://doc.traefik.io/traefik/providers/ecs/) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="vpc_id"></a> [vpc\_id](#input\_vpc_id) | The ID of the VPC to of the ECS cluster | `string` | `{}` | yes |
| <a name="nlb_arn"></a> [nlb\_arn](#input\_nlb_arn) | The ARN of the NLB to deploy to | `string` | `{}` | yes |
| <a name="default_acm_arn"></a> [default\_acm\_arn](#input\_default_acm_arn) | The ARN of the Default Certificate for SSL | `string` | `{}` | yes |
| <a name="ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs_cluster_name) | The Name of the ECS Cluster | `string` | `{}` | yes |
| <a name="public_subnets_ipv4"></a> [public\_subnets\_ipv4](#input\_public_subnets_ipv4) | VPC Subnets IPv4 - Public | `string` | `{}` | yes |
| <a name="public_subnets_ipv6"></a> [public\_subnets\_ipv6](#input\_public_subnets_ipv6) | VPC Subnets IPv6 - Public | `string` | `{}` | yes |
| <a name="private_subnets_ipv4"></a> [private\_subnets\_ipv4](#input\_private_subnets_ipv4) | VPC Subnets IPv4 - Private | `string` | `{}` | yes |
| <a name="private_subnets_ipv6"></a> [private\_subnets\_ipv6](#input\_private_subnets_ipv6) | VPC Subnets IPv6 - Private | `string` | `{}` | yes |
| <a name="http_port (Optional)"></a> [http\_port](#input\_http_port) | The Name HTTP Port of the Treafik Container | `string` | `80` | no |
| <a name="https_port (Optional)"></a> [https\_port](#input\_https_port) | The Name HTTPS Port of the Treafik Container | `string` | `443` | no |
| <a name="traefik_version (Optional)"></a> [traefik\_version](#input\_traefik_version) | Treafik Container Version| `string` | `latest` | no |
| <a name="traefik_log_level (Optional)"></a> [traefik\_log\_level](#input\_traefik_log_level) | Treafik Log Level | `string` | `ERROR` | no |


## Outputs

| Name | Description |
|------|-------------|
| <a name="security_group_id"></a> [security\_group\_id](#output\_security_group_id) | security_group_id |
| <a name="http_target_group_arn"></a> [http\_target\_group\_arn](#output\_http_target_group_arn) | http_target_group_arn |
| <a name="https_target_group_arn"></a> [https\_target\_group\_arn](#output\_https_target_group_arn) | https_target_group_arn |
| <a name="http_lb_listener_arn"></a> [http\_lb\_listener\_arn](#output\_http_lb_listener_arn) | http_lb_listener_arn |
| <a name="https_lb_listener_arn"></a> [https\_lb\_listener\_arn](#output\_https_lb_listener_arn) | https_lb_listener_arn |
| <a name="traefik_ecs_task_arn"></a> [traefik\_ecs\_task\_arn](#\_traefik_ecs_task_arn) | traefik_ecs_task_arn |
| <a name="traefik_ecs_task_revision"></a> [traefik\_ecs\_task\_revision](#\_traefik_ecs_task_revision) | traefik_ecs_task_revision |
| <a name="traefik_ecs_service_id"></a> [traefik\_ecs\_service\_id](#\_traefik_ecs_service_id) | traefik_ecs_service_id |

## Authors

Module is maintained by [Forum One Communications](https://www.forumone.com).
