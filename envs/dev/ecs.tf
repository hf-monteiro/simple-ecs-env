//****START MAIN ECS CONFIGURATION****
//All of the ECS configuration and resources that will be shared between services is created here
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
//****SHIPPING SERVICE****
resource "aws_iam_role" "Example-ship-dev-task-role" {
    name = "Example-ship-task-role"

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

resource "aws_iam_policy" "Example-ship-dev-task-policy" {
  name        = "Example-ship-dev-task-policy"
  path        = "/"
  description = "Grants permissions needed by the Examplewl Shipping tasks/service"
  policy      = templatefile("policy-docs/Example-ship-dev-task-policy.tftpl", { bucketARN = aws_s3_bucket.Example-shipping-bucket.arn })
}

resource "aws_iam_role_policy_attachment" "Example-ship-dev-task-policy-attachment" {
  role       = aws_iam_role.Example-ship-dev-task-role.name
  policy_arn = aws_iam_policy.Example-ship-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-ship-dev" {

  family                   = "Example-ship-dev"
  task_role_arn            = aws_iam_role.Example-ship-dev-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("container-defs/Example-ship.json")
}

resource "aws_lb_target_group" "Example-ship-dev-tg" {
  name        = "Example-ship-dev"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.Example-dev.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.Example-ship-dev-lb]
}

resource "aws_alb" "Example-ship-dev-lb" {
  name               = "Example-ship-dev"
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
resource "aws_alb_listener" "Example-ship-dev-http-listener" {
  load_balancer_arn = aws_alb.Example-ship-dev-lb.arn
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

resource "aws_alb_listener" "Example-ship-dev-https-listener" {
  load_balancer_arn = aws_alb.Example-ship-dev-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.dev-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Example-ship-dev-tg.arn
  }
}

resource "aws_ecs_service" "Example-ship-dev" {
  name                               = "Example-shipping-dev"
  cluster                            = aws_ecs_cluster.dev-cluster.id
  task_definition                    = aws_ecs_task_definition.Example-ship-dev.arn
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
//****END SHIPPING SERVICE****
//****START ECOMMERCE_SERVICE SERVICE****
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
//****END ECOMMERCE SERVICE
//****REPORTING SERVICE****
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
//****END REPORTING SERVICE****
//****CSV SERVICE****
resource "aws_iam_role" "csv-service-task-role" {
    name = "Example-csv-service-task-role"

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

resource "aws_iam_policy" "Example-csv-service-dev-task-policy" {
    name = "Example-csv-service-dev-task-policy"
    path = "/"
    description = "Grants permissions needed by the Examplewl CSV service tasks/services"
    policy = templatefile("policy-docs/Example-csv-dev-task-policy.tftpl", {bucketARN = aws_s3_bucket.Example-csv-service-bucket.arn, queueARN = aws_sqs_queue.csv-service-dev.arn})
}

resource "aws_iam_role_policy_attachment" "Example-csv-service-dev-task-policy-attachment" {
    role = aws_iam_role.csv-service-task-role.name
    policy_arn = aws_iam_policy.Example-csv-service-dev-task-policy.arn
}

resource "aws_ecs_task_definition" "Example-csv-dev" {
    family = "Example-csv-dev"
    task_role_arn = aws_iam_role.csv-service-task-role.arn
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    requires_compatibilities = ["FARGATE"]
    container_definitions = "${file("container-defs/Example-csv-service.json")}"
}
resource "aws_lb_target_group" "Example-csv-service-dev-tg" {
    name = "Example-csv-service-dev"
    port = 8080
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.Example-dev.id

    health_check {
        enabled = true
        path = "/health"
    }

    depends_on = [aws_alb.Example-csv-service-dev-lb]
}

resource "aws_alb" "Example-csv-service-dev-lb" {
    name = "Example-csv-service-dev"
    internal = false
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public-subnets["public-1a"].id,
        aws_subnet.public-subnets["public-1b"].id,
        aws_subnet.public-subnets["public-1c"].id
    ]

    security_groups = [aws_security_group.Example-dev-lbs.id]
}

resource "aws_alb_listener" "Example-csv-service-dev-http-listener" {
    load_balancer_arn = aws_alb.Example-csv-service-dev-lb.arn
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

resource "aws_alb_listener" "Example-csv-service-dev-https-listener" {
    load_balancer_arn = aws_alb.Example-csv-service-dev-lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = data.aws_acm_certificate.dev-cert.arn

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.Example-csv-service-dev-tg.arn
    }
}

resource "aws_ecs_service" "Example-csv-service-dev" {
    name = "Example-csv-service-dev"
    cluster = aws_ecs_cluster.dev-cluster.id
    task_definition = aws_ecs_task_definition.Example-csv-dev.arn
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
//****END CSV SERVICE CONFIGURATION****
//****START IMAGE_SERVICE ****
//****START IMAGESERVICE ****
resource "aws_iam_role" "Example-imageservice-dev-task-role" {
    name = "Example-imageservice-task-role"

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
resource "aws_iam_policy" "Example-imageservice-dev-task-policy" {
    name = "Example-imageservice-dev-task-policy"
    path = "/"
    description = "Grants permissions needed by the Examplewl Image Service tasks/service"
    policy = templatefile("policy-docs/Example-imageservice-dev-task-policy.tftpl", {bucketARN = aws_s3_bucket.Example-imageservice-bucket.arn})
}

resource "aws_iam_role_policy_attachment" "Example-imageservice-dev-task-policy-attachment" {
    role = aws_iam_role.Example-imageservice-dev-task-role.name
    policy_arn = aws_iam_policy.Example-imageservice-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-imageservice-dev" {
    family = "Example-imageservice-dev"
    task_role_arn = aws_iam_role.Example-imageservice-dev-task-role.arn
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    requires_compatibilities = ["FARGATE"]
    container_definitions = "${file("container-defs/Example-imageservice.json")}"
}
resource "aws_lb_target_group" "Example-imageservice-dev-tg" {
    name = "Example-imageservice-dev"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.Example-dev.id

    health_check {
        enabled = true
        path = "/health"
    }

    depends_on = [aws_alb.Example-imageservice-dev-lb]
}

resource "aws_alb" "Example-imageservice-dev-lb" {
    name = "Example-imageservice-dev"
    internal = false
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public-subnets["public-1a"].id,
        aws_subnet.public-subnets["public-1b"].id,
        aws_subnet.public-subnets["public-1c"].id
    ]

    security_groups = [aws_security_group.Example-dev-lbs.id]
}

resource "aws_alb_listener" "Example-imageservice-dev-http-listener" {
    load_balancer_arn = aws_alb.Example-imageservice-dev-lb.arn
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
resource "aws_alb_listener" "Example-imageservice-dev-https-listener" {
    load_balancer_arn = aws_alb.Example-imageservice-dev-lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = data.aws_acm_certificate.dev-cert.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.Example-imageservice-dev-tg.arn
    }
}
resource "aws_ecs_service" "Example-imageservice-dev" {
    name = "Example-imageservice-dev"
    cluster = aws_ecs_cluster.dev-cluster.id
    task_definition = aws_ecs_task_definition.Example-imageservice-dev.arn
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
//****END END IMAGE SERVICE
//****PAYMENTSERVICE****
resource "aws_iam_role" "Example-paymentservice-dev-task-role" {
    name = "Example-ecs-paymentservice-task-role"

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

resource "aws_iam_policy" "Example-paymentservice-dev-task-policy" {
    name = "Example-paymentservice-dev-task-policy"
    path = "/"
    description = "Grants permissions needed by the Examplewl Payment Service tasks/service"
    policy = templatefile("policy-docs/Example-paymentservice-dev-task-policy.tftpl", {})
}

resource "aws_iam_role_policy_attachment" "Example-paymentservice-dev-task-policy-attachment" {
    role = aws_iam_role.Example-paymentservice-dev-task-role.name
    policy_arn = aws_iam_policy.Example-paymentservice-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-paymentservice-dev" {
    
    family = "Example-paymentservice-dev"
    task_role_arn = aws_iam_role.Example-paymentservice-dev-task-role.arn
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    requires_compatibilities = ["FARGATE"]
    container_definitions = "${file("container-defs/Example-paymentservice.json")}"
}

resource "aws_lb_target_group" "Example-paymentservice-dev-tg" {
    name = "Example-paymentservice-dev"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.Example-dev.id

    health_check {
      enabled = true
      path = "/health"
    }

    depends_on = [aws_alb.Example-paymentservice-dev-lb]
}

resource "aws_alb" "Example-paymentservice-dev-lb" {
    name = "Example-paymentservice-dev"
    internal = false
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public-subnets["public-1a"].id,
        aws_subnet.public-subnets["public-1b"].id,
        aws_subnet.public-subnets["public-1c"].id
    ]

    security_groups = [aws_security_group.Example-dev-lbs.id]
}

//We should not be forwarding HTTP requests. Redirect to HTTPS
resource "aws_alb_listener" "Example-paymentservice-dev-http-listener" {
    load_balancer_arn = aws_alb.Example-paymentservice-dev-lb.arn
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

resource "aws_alb_listener" "Example-paymentservice-dev-https-listener" {
    load_balancer_arn = aws_alb.Example-paymentservice-dev-lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = data.aws_acm_certificate.dev-cert.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.Example-paymentservice-dev-tg.arn
    }
}

resource "aws_ecs_service" "Example-paymentservice-dev" {
    name = "Example-paymentservice-dev"
    cluster = aws_ecs_cluster.dev-cluster.id
    task_definition = aws_ecs_task_definition.Example-paymentservice-dev.arn
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
//****END PAYMENTSERVICE****
//****ONLINE-SERVER SERVICE****
resource "aws_iam_role" "Example-online-server-dev-task-role" {
    name = "Example-ecs-online-server-task-role"

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

resource "aws_iam_policy" "Example-online-server-dev-task-policy" {
    name = "Example-online-server-dev-task-policy"
    path = "/"
    description = "Grants permissions needed by the Examplewl Online Server tasks/service"
    policy = templatefile("policy-docs/Example-online-server-dev-task-policy.tftpl", {bucketARN = aws_s3_bucket.Example-online-server-bucket.arn, queueARN = aws_sqs_queue.online-server-dev.arn})
}

resource "aws_iam_role_policy_attachment" "Example-online-server-dev-task-policy-attachment" {
    role = aws_iam_role.Example-online-server-dev-task-role.name
    policy_arn = aws_iam_policy.Example-online-server-dev-task-policy.arn
}
resource "aws_ecs_task_definition" "Example-online-server-dev" {
    
    family = "Example-online-server-dev"
    task_role_arn = aws_iam_role.Example-online-server-dev-task-role.arn
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    requires_compatibilities = ["FARGATE"]
    container_definitions = "${file("container-defs/Example-online-server.json")}"
}

resource "aws_lb_target_group" "Example-online-server-dev-tg" {
    name = "Example-online-server-dev"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.Example-dev.id

    health_check {
      enabled = true
      path = "/health"
    }

    depends_on = [aws_alb.Example-online-server-dev-lb]
}

resource "aws_alb" "Example-online-server-dev-lb" {
    name = "Example-online-server-dev"
    internal = false
    load_balancer_type = "application"

    subnets = [
        aws_subnet.public-subnets["public-1a"].id,
        aws_subnet.public-subnets["public-1b"].id,
        aws_subnet.public-subnets["public-1c"].id
    ]

    security_groups = [aws_security_group.Example-dev-lbs.id]
}

//We should not be forwarding HTTP requests. Redirect to HTTPS
resource "aws_alb_listener" "Example-online-server-dev-http-listener" {
    load_balancer_arn = aws_alb.Example-online-server-dev-lb.arn
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

resource "aws_alb_listener" "Example-online-server-dev-https-listener" {
    load_balancer_arn = aws_alb.Example-online-server-dev-lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = data.aws_acm_certificate.dev-cert.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.Example-online-server-dev-tg.arn
    }
}

resource "aws_ecs_service" "Example-online-server-dev" {
    name = "Example-online-server-dev"
    cluster = aws_ecs_cluster.dev-cluster.id
    task_definition = aws_ecs_task_definition.Example-online-server-dev.arn
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
//****END ONLINE-SERVER SERVICE****
//****START ECOMMERCE****
resource "aws_iam_role" "Example-ecommerce-dev-task-role" {
  name = "Example-ecommerce-ecs-task-role"

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

resource "aws_iam_policy" "Example-ecommerce-dev-task-policy" {
  name        = "Example-ecommerce-dev-task-policy"
  path        = "/"
  description = "Grants permissions needed by the Examplewl Ecommerce tasks/service"
  policy      = templatefile("policy-docs/Example-ecommerce-dev-task-policy.tftpl", {bucketARN = aws_s3_bucket.Example-ecommerce-bucket.arn})
}

resource "aws_iam_role_policy_attachment" "Example-ecommerce-dev-task-policy-attachment" {
  role       = aws_iam_role.Example-ecommerce-dev-task-role.name
  policy_arn = aws_iam_policy.Example-ecommerce-dev-task-policy.arn
}

resource "aws_ecs_task_definition" "Example-ecommerce-dev" {

  family                   = "Example-ecommerce-dev"
  task_role_arn            = aws_iam_role.Example-ecommerce-dev-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = "${file("container-defs/Example-ecommerce.json")}"
}

resource "aws_lb_target_group" "Example-ecommerce-dev-tg" {
  name        = "Example-ecommerce-dev"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.Example-dev.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.Example-ecommerce-dev-lb]
}

resource "aws_alb" "Example-ecommerce-dev-lb" {
  name               = "Example-ecommerce-dev"
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
resource "aws_alb_listener" "Example-ecommerce-dev-http-listener" {
  load_balancer_arn = aws_alb.Example-ecommerce-dev-lb.arn
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

resource "aws_alb_listener" "Example-ecommerce-dev-https-listener" {
  load_balancer_arn = aws_alb.Example-ecommerce-dev-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.dev-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Example-ecommerce-dev-tg.arn
  }
}

resource "aws_ecs_service" "Example-ecommerce-dev" {
  name                               = "Example-ecommerce-dev"
  cluster                            = aws_ecs_cluster.dev-cluster.id
  task_definition                    = aws_ecs_task_definition.Example-ecommerce-dev.arn
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
//****END ECOMMERCE****
//****END MAIN ECS CONFIGURATION****
