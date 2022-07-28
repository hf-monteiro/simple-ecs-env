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
//****example SERVICE01****
resource "aws_iam_role" "Example-example-dev-task-role" {
    name = "Example-example-task-role"

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

resource "aws_iam_policy" "Example-example-dev-task-policy" {
  name        = "Example-example-dev-task-policy"
  path        = "/"
  description = "Grants permissions needed by the Examplewl example tasks/service"
  policy      = templatefile("policy-docs/Example-example-dev-task-policy.tftpl", { bucketARN = aws_s3_bucket.Example-example-bucket.arn })
}

resource "aws_iam_role_policy_attachment" "Example-example-dev-task-policy-attachment" {
  role       = aws_iam_role.Example-example-dev-task-role.name
  policy_arn = aws_iam_policy.Example-example-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-example-dev" {

  family                   = "Example-example-dev"
  task_role_arn            = aws_iam_role.Example-example-dev-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("container-defs/Example-example.json")
}

resource "aws_lb_target_group" "Example-example-dev-tg" {
  name        = "Example-example-dev"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.Example-dev.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.Example-example-dev-lb]
}

resource "aws_alb" "Example-example-dev-lb" {
  name               = "Example-example-dev"
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
resource "aws_alb_listener" "Example-example-dev-http-listener" {
  load_balancer_arn = aws_alb.Example-example-dev-lb.arn
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

resource "aws_alb_listener" "Example-example-dev-https-listener" {
  load_balancer_arn = aws_alb.Example-example-dev-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.dev-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Example-example-dev-tg.arn
  }
}

resource "aws_ecs_service" "Example-example-dev" {
  name                               = "Example-example-dev"
  cluster                            = aws_ecs_cluster.dev-cluster.id
  task_definition                    = aws_ecs_task_definition.Example-example-dev.arn
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
//****END example SERVICE01****
//****START SERVICE02****
resource "aws_iam_role" "Example-ecommerce-service-dev-task-role" {
    name = "Example-ecommerce-service-task-role"

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
resource "aws_iam_policy" "Example-ecommerce-service-dev-task-policy" {
    name = "Example-ecommerce-service-dev-task-policy"
    path = "/"
    description = "Grants permissions needed by the Examplewl Ecommerce Service tasks/service"
    policy = templatefile("policy-docs/Example-ecommerce-service-dev-task-policy.tftpl", {queueARN = aws_sqs_queue.ecommerce-dev.arn})
}

resource "aws_iam_role_policy_attachment" "Example-ecommerce-service-dev-task-policy-attachment" {
    role = aws_iam_role.Example-ecommerce-service-dev-task-role.name
    policy_arn = aws_iam_policy.Example-ecommerce-service-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-ecommerce-service-dev" {
    family = "Example-ecommerce-service-dev"
    task_role_arn = aws_iam_role.Example-ecommerce-service-dev-task-role.arn
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    requires_compatibilities = ["FARGATE"]
    container_definitions = "${file("container-defs/ecommerce-service.json")}"
}
resource "aws_lb_target_group" "Example-ecommerce-service-dev-tg" {
    name = "Example-ecommerce-service-dev"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.Example-dev.id

    health_check {
        enabled = true
        path = "/health"
    }

    depends_on = [aws_alb.Example-ecommerce-service-dev-lb]
}

resource "aws_alb" "Example-ecommerce-service-dev-lb" {
    name = "Example-ecommerce-service-dev"
    internal = false
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public-subnets["public-1a"].id,
        aws_subnet.public-subnets["public-1b"].id,
        aws_subnet.public-subnets["public-1c"].id
    ]

    security_groups = [aws_security_group.Example-dev-lbs.id]
}

resource "aws_alb_listener" "Example-ecommerce-service-dev-http-listener" {
    load_balancer_arn = aws_alb.Example-ecommerce-service-dev-lb.arn
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
resource "aws_alb_listener" "Example-ecommerce-service-dev-https-listener" {
    load_balancer_arn = aws_alb.Example-ecommerce-service-dev-lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = data.aws_acm_certificate.dev-cert.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.Example-ecommerce-service-dev-tg.arn
    }
}
resource "aws_ecs_service" "Example-ecommerce-service-dev" {
    name = "Example-ecommerce-service-dev"
    cluster = aws_ecs_cluster.dev-cluster.id
    task_definition = aws_ecs_task_definition.Example-ecommerce-service-dev.arn
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
resource "aws_iam_role" "Example-report-dev-task-role" {
  name = "Example-report-ecs-task-role"

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

resource "aws_iam_policy" "Example-report-dev-task-policy" {
  name        = "Example-report-dev-task-policy"
  path        = "/"
  description = "Grants permissions needed by the Examplewl Reporting Service tasks/service"
  policy      = templatefile("policy-docs/Example-report-dev-task-policy.tftpl", { bucketARN = aws_s3_bucket.Example-reporting-bucket.arn })
}

resource "aws_iam_role_policy_attachment" "Example-report-dev-task-policy-attachment" {
  role       = aws_iam_role.Example-report-dev-task-role.name
  policy_arn = aws_iam_policy.Example-report-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-report-dev" {

  family                   = "Example-report-dev"
  task_role_arn            = aws_iam_role.Example-report-dev-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("container-defs/Example-report.json")
}

resource "aws_lb_target_group" "Example-report-dev-tg" {
  name        = "Example-report-dev"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.Example-dev.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.Example-report-dev-lb]
}

resource "aws_alb" "Example-report-dev-lb" {
  name               = "Example-report-dev"
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
resource "aws_alb_listener" "Example-report-dev-http-listener" {
  load_balancer_arn = aws_alb.Example-report-dev-lb.arn
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

resource "aws_alb_listener" "Example-report-dev-https-listener" {
  load_balancer_arn = aws_alb.Example-report-dev-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.dev-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Example-report-dev-tg.arn
  }
}

resource "aws_ecs_service" "Example-report-dev" {
  name                               = "Example-reportingservice-dev"
  cluster                            = aws_ecs_cluster.dev-cluster.id
  task_definition                    = aws_ecs_task_definition.Example-report-dev.arn
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
