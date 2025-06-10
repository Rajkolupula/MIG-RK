provider "aws" {
  region = "ap-south-1"  # Change to your preferred AWS region
}

# Launch Template (like GCP Instance Template)
resource "aws_launch_template" "template1" {
  name_prefix   = "template1-"
  image_id      = "ami-0f535a71b34f2d44a" # Example: Amazon Linux 2. Replace with your CentOS image
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = "subnet-08e7743364e914d40"  # You must set this
    security_groups             = [aws_security_group.harness_sg.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "harnessvms"
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode("#!/bin/bash\necho Hello World") # optional startup script
}

# Security Group
resource "aws_security_group" "harness_sg" {
  name        = "harness-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = "vpc-0ce1a53b168284efe"  # Replace with your VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Auto Scaling Group (like GCP Instance Group Manager)
resource "aws_autoscaling_group" "asg" {
  name                      = "instance-manager-1"
  max_size                  = 2
  min_size                  = 2
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = ["subnet-08e7743364e914d40"] # Replace with your subnet ID

  launch_template {
    id      = aws_launch_template.template1.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "harnessvms"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


