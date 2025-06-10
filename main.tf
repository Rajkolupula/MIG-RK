provider "aws" {
  region = "ap-south-1"
}

# Security Group allowing HTTP and SSH access
resource "aws_security_group" "harness_sg" {
  name        = "harness-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = "vpc-0ce1a53b168284efe"  # Replace with your actual VPC ID

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for EC2
resource "aws_launch_template" "template1" {
  name_prefix   = "template1-"
  image_id      = "ami-0f535a71b34f2d44a"  # CentOS-based AMI. Update if needed.
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = "subnet-08e7743364e914d40"  # Replace with your subnet ID
    security_groups             = [aws_security_group.harness_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "harnessvms"
    }
  }

  user_data = base64encode("#!/bin/bash\necho Hello World")
}

# Auto Scaling Group with 2 instances
resource "aws_autoscaling_group" "asg" {
  name                      = "instance-manager-1"
  max_size                  = 2
  min_size                  = 2
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = ["subnet-08e7743364e914d40"]  # Same as in launch template

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


