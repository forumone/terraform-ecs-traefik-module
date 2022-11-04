# Module Outputs
output "security_group_id" {
  value       = aws_security_group.traefik_ecs.security_group_id
  description = "The Security Group IP of the Traefik ECS Security Group"
}
output "http_target_group_arn" {
  value       = aws_lb_target_group.traefik_http.target_group_arn
  description = "The Traefik HTTP Target"
}
output "https_target_group_arn" {
  value       = aws_lb_target_group.traefik_https.target_group_arn
  description = "The Traefik HTTPS Target"
}
output "http_lb_listener_arn" {
  value       = aws_lb_listener.traefik_http.arn
  description = "The Traefik HTTP Listener ARN"
}
output "https_lb_listener_arn" {
  value       = aws_lb_listener.traefik_https.arn
  description = "The Traefik HTTPS Listener ARN"
}
output "traefik_ecs_task_arn" {
  value       = aws_ecs_task_definition.traefik.arn
  description = "The Traefik ECS Task ARN"
}
output "traefik_ecs_task_revision" {
  value       = aws_ecs_task_definition.traefik.revision
  description = "The Traefik ECS Task Revision"
}
output "traefik_ecs_service_id" {
  value       = aws_ecs_service.traefik.id
  description = "The Traefik ECS Service ID"
}
