locals {
   common_tags = {
      Name        = "terraform-training"
      Environment = var.env_type
      Department = "Finance"
   } 
   local-subnet-ids = split(",", var.subnet-ids)
   subnet1 = length(split(",", var.subnet-ids))-1
   subnet2 = length(split(",", var.subnet-ids))-2
}

resource "aws_launch_template" "master_asg_template" {
  name_prefix                          = "master_asg_template"
  # image_id                             = data.aws_ami.amazon-linux-2.id
  image_id                =     lookup(var.aws_amis, var.region, "")
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  key_name                             = var.key_name

  # provisioner "remote-exec" {
  #   inline = [
  #     "yum -y install httpd",
  #     "systemctl enable httpd",
  #     "systemctl start httpd",
  #   ]
  # } 
  
  tags = {
    Name = "terraformWeb"
  }
}


resource "aws_autoscaling_group" "master_asg" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1

  health_check_grace_period = 300
  health_check_type         = "EC2"
  load_balancers            = [aws_elb.web_elb.id]
  vpc_zone_identifier       = [element(local.local-subnet-ids,local.subnet1),element(local.local-subnet-ids,local.subnet2)]
  # vpc_zone_identifier       = local.local-subnet-ids

  tags = [local.common_tags]

  launch_template {
    id      = aws_launch_template.master_asg_template.id
    version = "$Latest"
  }
}
resource "aws_security_group" "webserver-sg" {
  provider    = aws
  name        = "webserver-sg-${timestamp()}"
  description = "Allow TCP/80 & TCP/443"
  tags = merge(
            local.common_tags,
            {
              extra_tags = "example"
              extra_more_tag = "anothgertag"
            }
  )


  ingress {
    description = "Allow 443 from our public IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "allow anyone on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow anyone on port 22 for ssh"
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
