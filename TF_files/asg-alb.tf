#provider "aws" {
#  region = "us-east-1"
#}

#terraform {
#  backend "s3" {
#    # Replace this with your bucket name!
#    bucket         = "terraform-up-and-running-state"
#    key            = "global/s3/terraform.tfstate"
#    region         = "us-east-1"
#    ## Replace this with your DynamoDB table name!
#    #dynamodb_table = "terraform-up-and-running-locks"
#    #encrypt        = true
#  }
#}

# New ALB
resource "aws_alb" "alb_prod" {
  name            = "alb-prod"
  security_groups = [aws_security_group.alb_prod.id]
  subnets         = aws_subnet.ft_prod.*.id
  tags = {
    Name = "ft-alb-prod"
  }
}

resource "aws_alb" "alb_dev" {
  name            = "alb-dev"
  security_groups = [aws_security_group.alb_dev.id]
  subnets         = aws_subnet.ft_dev.*.id
  tags = {
    Name = "ft-alb-dev"
  }
}

#New Target Groups
resource "aws_alb_target_group" "group_prod" {
  name     = "alb-target-prod"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ft_vpc.id
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_alb_target_group" "group_dev" {
  name     = "alb-target-dev"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ft_vpc.id
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
}

#New ALB Listener
resource "aws_alb_listener" "listener_http_prod" {
  load_balancer_arn = aws_alb.alb_prod.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group_prod.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "listener_http_dev" {
  load_balancer_arn = aws_alb.alb_dev.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group_dev.arn
    type             = "forward"
  }
}

#EC2 Launch Configuration
resource "aws_launch_configuration" "launch_config" {
  name_prefix   = "terraform-instance"
  image_id      = "ami-087c17d1fe0178315"
  instance_type = "t2.micro"
  key_name                    = "terraform-key"
  security_groups             = ["${aws_security_group.default_ft.id}"]
  associate_public_ip_address = true
  #user_data                   = "${data.template_file.provision.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group_prod" {
  launch_configuration = aws_launch_configuration.launch_config.id
  desired_capacity     = "1"
  min_size             = "1"
  max_size             = "1"
  target_group_arns    = ["${aws_alb_target_group.group_prod.arn}"]
  vpc_zone_identifier  = aws_subnet.ft_prod.*.id

  tag {
    key                 = "Name"
    value               = "terraform-autoscaling-group-prod"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group_dev" {
  launch_configuration = aws_launch_configuration.launch_config.id
  desired_capacity     = "1"
  min_size             = "1"
  max_size             = "1"
  target_group_arns    = ["${aws_alb_target_group.group_dev.arn}"]
  vpc_zone_identifier  = aws_subnet.ft_dev.*.id

  tag {
    key                 = "Name"
    value               = "terraform-autoscaling-group-dev"
    propagate_at_launch = true
  }
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-087c17d1fe0178315"
  instance_type               = "t2.micro"
  key_name                    = "terraform-key"
  security_groups             = ["${aws_security_group.jenkins.id}"]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.ft_jenkins.id
}
