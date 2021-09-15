provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "ft-terraform-up-and-running-state"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
    ## Replace this with your DynamoDB table name!
    #dynamodb_table = "ft-terraform-up-and-running-locks"
    #encrypt        = true
  }
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "ft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags  = {
    Name = "ft-vpc"
  }
}

resource "aws_internet_gateway" "ft_gateway" {
  vpc_id = aws_vpc.ft_vpc.id

  tags = {
    Name = "ft-gateway"
  }
}

resource "aws_route" "ft_route" {
  route_table_id         = aws_vpc.ft_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ft_gateway.id
}

#Subnet jenkins
resource "aws_subnet" "ft_jenkins" {
  vpc_id            = aws_vpc.ft_vpc.id
  cidr_block        = "10.0.200.0/24"
  availability_zone = "us-east-1a"
  tags =  {
    Name = "ft-sub-jenkins"
  }
}

#Subnet Prod
resource "aws_subnet" "ft_prod" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.ft_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "ft-prod-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}


#Subnet Dev
resource "aws_subnet" "ft_dev" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.ft_vpc.id
  cidr_block              = "10.0.${100+count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "ft-dev-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

#SG for DEV
resource "aws_security_group" "alb_dev" {
  name = "alb_dev-security-group"

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow output
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#SG for PROD
resource "aws_security_group" "alb_prod" {
  name = "alb_prod-security-group"

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow output
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#SG for Jenkins
resource "aws_security_group" "jenkins" {
  name = "jenkins-security-group"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow output
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
