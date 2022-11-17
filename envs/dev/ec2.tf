#----------------------------------------------------------
#  ECS Instace
#----------------------------------------------------------

resource "aws_instance" "web" {
  ami                    = "ami-0c9bfc21ac5bf10eb" // Amazon Linux2
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.general-sg.id]
  user_data              = file("user_data.sh") // Static File
  tags = {
    Name  = "WebServer"
    Terraform = "True"
 }
  depends_on = [aws_instance.db]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "db" {
  ami                    = "ami-0c9bfc21ac5bf10eb" // Amazon Linux2
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.general-sg.id]
  user_data              = file("user_data.sh") // Static File
  tags = {
    Name  = "WebServer"
    Terraform = "True"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "general-sg" {
  name        = "general-SG"
  description = "Security Group for my whole application"
  vpc_id      = aws_vpc.Example-dev.id

  dynamic "ingress" {
    for_each = ["80", "8080", "443", "1000", "8443"]
    content {
      description = "Allow ports"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow ALL ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "WebServer"
    Terraform = "True"
  }
}