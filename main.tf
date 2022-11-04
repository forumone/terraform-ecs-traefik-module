# Get the current aws region
data "aws_region" "current" {}

# Gather Data About the VPC subnets
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc.name}-private-*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc.name}-public-*"]
  }
}

# Create Cloudwatch Log group
resource "aws_cloudwatch_log_group" "traefik" {
  name              = "${var.ecs_cluster}/traefik/"
  retention_in_days = 14
}

#Create IAM Roles and Policies
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
      "ec2:DescribeInstances"
    ]

    resources = [
      "*",
    ]
  }
}

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

resource "aws_iam_role" "traefik" {
  name = "${var.ecs_cluster}-traefik-task_role"

  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}


resource "aws_iam_role_policy" "traefik_policy" {
  name = "${var.ecs_cluster}-traefik-policy"
  role = aws_iam_role.traefik.id

  policy = data.aws_iam_policy_document.traefik_policy.json
}

resource "aws_iam_role" "ecs_role" {
  name = "${var.ecs_cluster}-traefik-ecs-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy_secrets" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.ecs_role.name
}

# Create Security groups
resource "aws_security_group" "traefik_ecs" {
  name        = "traefik_ecs"
  description = "Security group for the Traefik reverse proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.ecs_cluster}-treafik"
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
  cidr_blocks       = [var.public_subnets_ipv4]
  ipv6_cidr_blocks  = [var.public_subnets_ipv6]
}

resource "aws_security_group_rule" "public_traefik_https_ingress" {
  description       = "Allows incoming HTTPS traffic from public subnets"
  security_group_id = aws_security_group.traefik_ecs.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  cidr_blocks       = [var.public_subnets_ipv4]
  ipv6_cidr_blocks  = [var.public_subnets_ipv6]
}


# Create Network Load Balanacer Target Groups
resource "aws_lb_target_group" "traefik_http" {
  name        = "traefik-http"
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
  name        = "traefik-https"
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
  load_balancer_arn = var.nlb_id
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.traefik_http.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "traefik_https" {
  load_balancer_arn = var.nlb_id
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = var.default_acm
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
      name       = "traefik"
      image      = "traefik:${var.traefik_version}"
      entryPoint = ["traefik", "--providers.ecs.clusters", "${var.ecs_cluster}", "--log.level", "${var.traefik_log_level}", "--providers.ecs.region", "${data.aws_region.current.name}"]
      essential  = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${var.ecs_cluster}/traefik/"
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
  name            = "${var.ecs_cluster}-traefik"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.traefik.arn
  desired_count   = 1
  launch_type     = "FARGATE"


  load_balancer {
    target_group_arn = aws_lb_target_group.traefik_http.id
    container_name   = "traefik"
    container_port   = var.http_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.traefik_https.id
    container_name   = "traefik"
    container_port   = var.https_port
  }

  network_configuration {
    subnets         = toset(data.aws_subnets.private.ids)
    security_groups = [aws_security_group.traefik_ecs.id]
  }
}
