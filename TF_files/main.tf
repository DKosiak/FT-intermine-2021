provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-up-and-running-state"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    ## Replace this with your DynamoDB table name!
    #dynamodb_table = "terraform-up-and-running-locks"
    #encrypt        = true
  }
}

resource "aws_vpc" "ft_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags {
    Name = "ft-vpc"
  }
}

resource "aws_internet_gateway" "ft_gateway" {
  vpc_id = "${aws_vpc.ft_vpc.id}"

  tags {
    Name = "ft-gateway"
  }
}

resource "aws_route" "ft_route" {
  route_table_id         = "${aws_vpc.ft_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ft_gateway.id}"
}

#Subnet jenkins
resource "aws_subnet" "ft_jenkins" {
  vpc_id = "${aws_vpc.ft_vpc.id}"
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "us-east-1a"
  tags {
    Name = "ft-sub-jenkins"
  }
}

#Subnet Prod
resource "aws_subnet" "ft_prod" {
  vpc_id = "${aws_vpc.ft_vpc.id}"
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
}
resource "aws_subnet" "ft_prod" {
  vpc_id = "${aws_vpc.ft_vpc.id}"
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-1b"
}

#Subnet Dev
resource "aws_subnet" "ft_dev" {
  vpc_id = "${aws_vpc.ft_vpc.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
}
resource "aws_subnet" "ft_dev" {
  vpc_id = "${aws_vpc.ft_vpc.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
}


#SG for DEV
resource "aws_security_group" "alb_dev" {
    name = "alb_dev-security-group"

    # Allow HTTP
    ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow output
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}
#SG for PROD
resource "aws_security_group" "alb_prod" {
    name = "alb_prod-security-group"

    # Allow HTTP
    ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow output
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

#SG for Jenkins
resource "aws_security_group" "jenkins" {
  name = "jenkins-security-group"

  ingress {
    from_port        = 8080
    to_port            = 8080
    protocol        = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
    }
    # Allow output
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}
