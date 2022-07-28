data "aws_secretsmanager_secret" "secrets" {
    name = "dev/Example-example"
}
data "aws_secretsmanager_secret_version" "current" {
    secret_id = data.aws_secretsmanager_secret.secrets.id
}
data "aws_secretsmanager_secret" "ecommerce" {
    name = "dev/Example-ecommerce-service"
}

data "aws_secretsmanager_secret_version" "ecom-current" {
    secret_id = data.aws_secretsmanager_secret.ecommerce.id
}
data "aws_acm_certificate" "dev-cert" {
    domain = "dev.Examplewlonline.com"
}
variable "account" {
  type    = string
  default = "000000000000"
}
variable "public-subnets" {
  type = map(any)
  default = {
    public-1a = {
      az   = "us-east-1a"
      cidr = "172.42.1.0/24"
    }
    public-1b = {
      az   = "us-east-1b"
      cidr = "172.42.2.0/24"
    }
    public-1c = {
      az   = "us-east-1c"
      cidr = "172.42.3.0/24"
    }
  }
}

variable "private-subnets" {
  type = map(any)
  default = {
    private-1a = {
      az   = "us-east-1a"
      cidr = "172.42.4.0/24"
    }

    private-1b = {
      az   = "us-east-1b"
      cidr = "172.42.5.0/24"
    }

    private-1c = {
      az   = "us-east-1c"
      cidr = "172.42.6.0/24"
    }
  }

}

variable broker_name {
  default = "report-service"  
}

variable engine_version {
  default = "3.8.6"
}

variable engine_type {
  default = "RabbitMQ"
}

variable host_instance_type {
  default = "mq.m5.large"
}

variable username {
  default = "mymquser"
}

variable password {
  default = "mymqpassword"
}

variable deployment_mode {
  default = "CLUSTER_MULTI_AZ"
}

variable publicly_accessible {
  default = true
}

variable mq_cluster_instance_count {
  default = "1"
}

variable storage_type {
  default = "ebs"
}

