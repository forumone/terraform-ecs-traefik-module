# Get the current aws region
data "aws_region" "current" {}

# Get the Public and Private VPC subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-private-*"]
  }
}

# Create Cloudwatch Log group
resource "aws_cloudwatch_log_group" "traefik" {
  name              = "${var.ecs_cluster_name}/traefik/"
  retention_in_days = 14
}

#Create IAM Roles and Policies
data "aws_iam_policy_document" "ecs_assume" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Create IAM Policy
data "aws_iam_policy_document" "traefik_policy" {
  statement {
    sid = "main"

    actions = [
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeContainerInstances",
      "ecs:DescribeTaskDefinition",
      "ec2:DescribeInstances",
      "ssm:DescribeInstanceInformation"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "traefik" {
  name               = "${var.ecs_cluster_name}-traefik-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy" "traefik_policy" {
  name   = "${var.ecs_cluster_name}-traefik-policy"
  role   = aws_iam_role.traefik.id
  policy = data.aws_iam_policy_document.traefik_policy.json
}

resource "aws_iam_role" "ecs_role" {
  name               = "${var.ecs_cluster_name}_traefik"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_role.name
}

# Create Security groups
resource "aws_security_group" "traefik_ecs" {
  name        = "${var.ecs_cluster_name}-traefik-ecs"
  description = "Security group for the Traefik reverse proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.ecs_cluster_name}-traefik"
  }
}

resource "aws_security_group_rule" "traefik_https_egress" {
  description       = "Allows outbound HTTPS (needed to pull Docker images)"
  security_group_id = aws_security_group.traefik_ecs.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "public_traefik_http_ingress" {
  description       = "Allows incoming HTTP traffic from public subnets"
  security_group_id = aws_security_group.traefik_ecs.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.http_port
  to_port           = var.http_port
  cidr_blocks       = toset(var.public_subnets_ipv4)
  ipv6_cidr_blocks  = toset(var.public_subnets_ipv6)
}

resource "aws_security_group_rule" "public_traefik_https_ingress" {
  description       = "Allows incoming HTTPS traffic from public subnets"
  security_group_id = aws_security_group.traefik_ecs.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  cidr_blocks       = toset(var.public_subnets_ipv4)
  ipv6_cidr_blocks  = toset(var.public_subnets_ipv6)
}

resource "aws_security_group_rule" "public_traefik_http_egress" {
  description       = "Allows incoming HTTP traffic from private subnets"
  security_group_id = aws_security_group.traefik_ecs.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.http_port
  to_port           = var.http_port
  cidr_blocks       = toset(var.private_subnets_ipv4)
  ipv6_cidr_blocks  = toset(var.private_subnets_ipv6)
}

resource "aws_security_group_rule" "public_traefik_https_egress" {
  description       = "Allows incoming HTTPS traffic from private subnets"
  security_group_id = aws_security_group.traefik_ecs.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  cidr_blocks       = toset(var.private_subnets_ipv4)
  ipv6_cidr_blocks  = toset(var.private_subnets_ipv6)
}


# Create Network Load Balanacer Target Groups
resource "aws_lb_target_group" "traefik_http" {
  name        = "${var.ecs_cluster_name}-traefik-http"
  port        = var.http_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled  = true
    interval = 10
    port     = var.http_port
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "traefik_https" {
  name        = "${var.ecs_cluster_name}-traefik-https"
  port        = var.https_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled  = true
    interval = 10
    port     = var.https_port
    protocol = "TCP"
  }
}

# Create Network Load Balanacer Target Listeners
resource "aws_lb_listener" "traefik_http" {
  load_balancer_arn = var.nlb_arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.traefik_http.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "traefik_https" {
  load_balancer_arn = var.nlb_arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = var.default_acm_arn
  default_action {
    target_group_arn = aws_lb_target_group.traefik_https.id
    type             = "forward"
  }
}

# Create ECS Task Definition
resource "aws_ecs_task_definition" "traefik" {
  family                   = "traefik"
  task_role_arn            = aws_iam_role.traefik.arn
  execution_role_arn       = aws_iam_role.ecs_role.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name  = "${var.ecs_cluster_name}-traefik"
      image = "traefik:${var.traefik_version}"
      entryPoint = [
        "traefik",
        "--providers.ecs.clusters",
        "${var.ecs_cluster_name}",
        "--log.level", "${var.traefik_log_level}",
        "--providers.ecs.region",
        "${data.aws_region.current.name}",
        "--providers.ecs.exposedByDefault=false",
        "--entryPoints.web.address=:${var.http_port}",
        "--entryPoints.web.http.redirections.entryPoint.to=websecure",
        "--entryPoints.websecure.address=:${var.https_port}",
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${var.ecs_cluster_name}/traefik/"
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-stream-prefix = "traefik"
        }
      }
      portMappings = [
        {
          containerPort = var.http_port
          hostPort      = var.http_port
        },
        {
          containerPort = var.https_port
          hostPort      = var.https_port
        }
      ]
    }
  ])
}

# Create ECS Service 
resource "aws_ecs_service" "traefik" {
  name            = "${var.ecs_cluster_name}-traefik"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.traefik.arn
  launch_type     = "FARGATE"


  load_balancer {
    target_group_arn = aws_lb_target_group.traefik_http.id
    container_name   = "${var.ecs_cluster_name}-traefik"
    container_port   = var.http_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.traefik_https.id
    container_name   = "${var.ecs_cluster_name}-traefik"
    container_port   = var.https_port
  }

  network_configuration {
    subnets         = toset(data.aws_subnets.private.ids)
    security_groups = [aws_security_group.traefik_ecs.id]
  }
}

# Create an autoscaling target for the traefik service
resource "aws_appautoscaling_target" "traefik" {
  # Tell autoscaling which AWS service resource this target is for.
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.traefik.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  # Permit 2-4 replicas by default - overridable
  min_capacity = var.autoscaling_min
  max_capacity = var.autoscaling_max
}

# Define a CPU-based scaling policy.  Autoscaling will attempt to maintain around 30% CPU
# utilization for the traefik service.
resource "aws_appautoscaling_policy" "traefik" {
  name        = "traefik-autoscaling-policy"
  policy_type = "TargetTrackingScaling"

  # Apply this policy to the traefik autoscaling target
  resource_id        = aws_appautoscaling_target.traefik.id
  scalable_dimension = aws_appautoscaling_target.traefik.scalable_dimension
  service_namespace  = aws_appautoscaling_target.traefik.service_namespace

  # Define the desired metric and threshold
  target_tracking_scaling_policy_configuration {
    target_value = 30

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }

}