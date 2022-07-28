//****START MAIN ECS CONFIGURATION****
resource "aws_ecs_cluster" "dev-cluster" {
  name = "Example-dev-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecs-task-execution-role" {
  name = "Example-ecs-task-execution-role"

  assume_role_policy = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "sts:AssumeRole",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Effect": "Allow",
                    "Sid": "ecsExecAllowAssume"
                }
            ]
        }
        EOF
}

resource "aws_iam_policy" "ecs-task-execution-addons" {
  name        = "ecs-task-execution-addons"
  path        = "/"
  description = "Grants permissions needed for launcing ECS tasks not provided by builtin AWS policy"
  policy      = "${file("policy-docs/task-execution-addons.json")}"
}
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-addons-attachment" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = aws_iam_policy.ecs-task-execution-addons.arn
}

//****END MAIN ECS CONFIGURATION****
//****START SERVICE SPECIFIC ECS CONFIGURATION****
//All service specific resources and configuration should be created here
//****START SERVICE01****
resource "aws_iam_role" "Example-service01-dev-task-role" {
    name = "Example-service01-task-role"

  assume_role_policy = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "sts:AssumeRole",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Effect": "Allow",
                    "Sid": "ecsTaskAllowAssume"
                }
            ]
        }
        EOF
}

resource "aws_iam_policy" "Example-service01-dev-task-policy" {
  name        = "Example-service01-dev-task-policy"
  path        = "/"
  description = "Grants permissions needed by the Examplewl service01 tasks/service"
  policy      = templatefile("policy-docs/Example-service01-dev-task-policy.tftpl", { bucketARN = aws_s3_bucket.Example-service01-bucket.arn })
}

resource "aws_iam_role_policy_attachment" "Example-service01-dev-task-policy-attachment" {
  role       = aws_iam_role.Example-service01-dev-task-role.name
  policy_arn = aws_iam_policy.Example-service01-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-service01-dev" {

  family                   = "Example-service01-dev"
  task_role_arn            = aws_iam_role.Example-service01-dev-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("container-defs/Example-service01.json")
}

resource "aws_lb_target_group" "Example-service01-dev-tg" {
  name        = "Example-service01-dev"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.Example-dev.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.Example-service01-dev-lb]
}

resource "aws_alb" "Example-service01-dev-lb" {
  name               = "Example-service01-dev"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public-subnets["public-1a"].id,
    aws_subnet.public-subnets["public-1b"].id,
    aws_subnet.public-subnets["public-1c"].id
  ]

  security_groups = [aws_security_group.Example-dev-lbs.id]
}

//We should not be forwarding HTTP requests. Redirect to HTTPS
resource "aws_alb_listener" "Example-service01-dev-http-listener" {
  load_balancer_arn = aws_alb.Example-service01-dev-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "Example-service01-dev-https-listener" {
  load_balancer_arn = aws_alb.Example-service01-dev-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.dev-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Example-service01-dev-tg.arn
  }
}

resource "aws_ecs_service" "Example-service01-dev" {
  name                               = "Example-service01-dev"
  cluster                            = aws_ecs_cluster.dev-cluster.id
  task_definition                    = aws_ecs_task_definition.Example-service01-dev.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups = [
      aws_security_group.Example-ecs-dev.id
    ]

    subnets = [
      aws_subnet.private-subnets["private-1a"].id,
      aws_subnet.private-subnets["private-1b"].id,
      aws_subnet.private-subnets["private-1c"].id
    ]

    assign_public_ip = false
  }
}
//****END SERVICE01****
//****START SERVICE02****
resource "aws_iam_role" "Example-service02-dev-task-role" {
    name = "Example-service02-task-role"

    assume_role_policy = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "sts:AssumeRole",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Effect": "Allow",
                    "Sid": "ecsTaskAllowAssume"
                }
            ]
        }
        EOF
}
resource "aws_iam_policy" "Example-service02-dev-task-policy" {
    name = "Example-service02-dev-task-policy"
    path = "/"
    description = "Grants permissions needed by the Example Service tasks/service"
    policy = templatefile("policy-docs/Example-service02-dev-task-policy.tftpl", {queueARN = aws_sqs_queue.service02-dev.arn})
}

resource "aws_iam_role_policy_attachment" "Example-service02-dev-task-policy-attachment" {
    role = aws_iam_role.Example-service02-dev-task-role.name
    policy_arn = aws_iam_policy.Example-service02-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-service02-dev" {
    family = "Example-service02-dev"
    task_role_arn = aws_iam_role.Example-service02-dev-task-role.arn
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    requires_compatibilities = ["FARGATE"]
    container_definitions = "${file("container-defs/service02.json")}"
}
resource "aws_lb_target_group" "Example-service02-dev-tg" {
    name = "Example-service02-dev"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.Example-dev.id

    health_check {
        enabled = true
        path = "/health"
    }

    depends_on = [aws_alb.Example-service02-dev-lb]
}

resource "aws_alb" "Example-service02-dev-lb" {
    name = "Example-service02-dev"
    internal = false
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public-subnets["public-1a"].id,
        aws_subnet.public-subnets["public-1b"].id,
        aws_subnet.public-subnets["public-1c"].id
    ]

    security_groups = [aws_security_group.Example-dev-lbs.id]
}

resource "aws_alb_listener" "Example-service02-dev-http-listener" {
    load_balancer_arn = aws_alb.Example-service02-dev-lb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "redirect"
        redirect {
            port = 443
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}
resource "aws_alb_listener" "Example-service02-dev-https-listener" {
    load_balancer_arn = aws_alb.Example-service02-dev-lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = data.aws_acm_certificate.dev-cert.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.Example-service02-dev-tg.arn
    }
}
resource "aws_ecs_service" "Example-service02-dev" {
    name = "Example-service02-dev"
    cluster = aws_ecs_cluster.dev-cluster.id
    task_definition = aws_ecs_task_definition.Example-service02-dev.arn
    desired_count = 1
    deployment_minimum_healthy_percent = 50
    deployment_maximum_percent = 200
    launch_type = "FARGATE"
    scheduling_strategy = "REPLICA"

    network_configuration {
        security_groups = [
            aws_security_group.Example-ecs-dev.id
        ]

        subnets = [
            aws_subnet.private-subnets["private-1a"].id,
            aws_subnet.private-subnets["private-1b"].id,
            aws_subnet.private-subnets["private-1c"].id
        ]

        assign_public_ip = false
    }
}
//****END SERVICE02 ###
//****START SERVICE03****
resource "aws_iam_role" "Example-service03-dev-task-role" {
  name = "Example-service03-ecs-task-role"

  assume_role_policy = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "sts:AssumeRole",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Effect": "Allow",
                    "Sid": "ecsTaskAllowAssume"
                }
            ]
        }
        EOF
}

resource "aws_iam_policy" "Example-service03-dev-task-policy" {
  name        = "Example-service03-dev-task-policy"
  path        = "/"
  description = "Grants permissions needed by the Examplewl service03 Service tasks/service"
  policy      = templatefile("policy-docs/Example-service03-dev-task-policy.tftpl", { bucketARN = aws_s3_bucket.Example-service03-bucket.arn })
}

resource "aws_iam_role_policy_attachment" "Example-service03-dev-task-policy-attachment" {
  role       = aws_iam_role.Example-service03-dev-task-role.name
  policy_arn = aws_iam_policy.Example-service03-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-service03-dev" {

  family                   = "Example-service03-dev"
  task_role_arn            = aws_iam_role.Example-service03-dev-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("container-defs/Example-service03.json")
}

resource "aws_lb_target_group" "Example-service03-dev-tg" {
  name        = "Example-service03-dev"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.Example-dev.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.Example-service03-dev-lb]
}

resource "aws_alb" "Example-service03-dev-lb" {
  name               = "Example-service03-dev"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public-subnets["public-1a"].id,
    aws_subnet.public-subnets["public-1b"].id,
    aws_subnet.public-subnets["public-1c"].id
  ]

  security_groups = [aws_security_group.Example-dev-lbs.id]
}

//We should not be forwarding HTTP requests. Redirect to HTTPS
resource "aws_alb_listener" "Example-service03-dev-http-listener" {
  load_balancer_arn = aws_alb.Example-service03-dev-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "Example-service03-dev-https-listener" {
  load_balancer_arn = aws_alb.Example-service03-dev-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.dev-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Example-service03-dev-tg.arn
  }
}

resource "aws_ecs_service" "Example-service03-dev" {
  name                               = "Example-service03service-dev"
  cluster                            = aws_ecs_cluster.dev-cluster.id
  task_definition                    = aws_ecs_task_definition.Example-service03-dev.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups = [
      aws_security_group.Example-ecs-dev.id
    ]

    subnets = [
      aws_subnet.private-subnets["private-1a"].id,
      aws_subnet.private-subnets["private-1b"].id,
      aws_subnet.private-subnets["private-1c"].id
    ]

    assign_public_ip = false
  }
}
//****END SERVICE03****
//****END MAIN ECS CONFIGURATION****
