# Provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.35.0"
    }
  }
}

provider "aws" {
  region  = var.region
}
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Project = "pratical-assignment"
    Name = "Practical VPC"
 }
}
# Create Public Subnet1
resource "aws_subnet" "pub_sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_sub1_cidr_block
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Project = "practical-assignment"
     Name = "public_subnet1"
 
 }
}

# Create Public Subnet2

resource "aws_subnet" "pub_sub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_sub2_cidr_block
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Project = "practical-assignment"
    Name = "public_subnet2" 
 }
}
# Create Private Subnet1
resource "aws_subnet" "prv_sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.prv_sub1_cidr_block
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Project = "practical-assignment"
    Name = "private_subnet1" 
 }
}
# Create Private Subnet2
resource "aws_subnet" "prv_sub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.prv_sub2_cidr_block
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false

  tags = {
    Project = "practical-assignment"
    Name = "private_subnet2"
  }
}
# Create Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Project = "practical-assignment"
    Name = "internet gateway" 
 }
}

# Create Public Route Table

resource "aws_route_table" "pub_sub1_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Project = "practical-assignment"
    Name = "public subnet route table" 
 }
}
# Create route table association of public subnet1
resource "aws_route_table_association" "internet_for_pub_sub1" {
  route_table_id = aws_route_table.pub_sub1_rt.id
  subnet_id      = aws_subnet.pub_sub1.id
}
# Create route table association of public subnet2

resource "aws_route_table_association" "internet_for_pub_sub2" {
  route_table_id = aws_route_table.pub_sub1_rt.id
  subnet_id      = aws_subnet.pub_sub2.id
}
# Create EIP for NAT GW1
  resource "aws_eip" "eip_natgw1" {
  count = "1"
}

# Create NAT gateway1

resource "aws_nat_gateway" "natgateway_1" {
  count         = "1"
  allocation_id = aws_eip.eip_natgw1[count.index].id
  subnet_id     = aws_subnet.pub_sub1.id
}

# Create EIP for NAT GW2

resource "aws_eip" "eip_natgw2" {
  count = "1"
}

# Create NAT gateway2

resource "aws_nat_gateway" "natgateway_2" {
  count         = "1"
  allocation_id = aws_eip.eip_natgw2[count.index].id
  subnet_id     = aws_subnet.pub_sub2.id
}
# Create private route table for prv sub1

resource "aws_route_table" "prv_sub1_rt" {
  count  = "1"
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway_1[count.index].id
  }
  tags = {
    Project = "practical-assignment"
    Name = "private subnet1 route table" 
 }
}
# Create route table association betn prv sub1 & NAT GW1

resource "aws_route_table_association" "pri_sub1_to_natgw1" {
  count          = "1"
  route_table_id = aws_route_table.prv_sub1_rt[count.index].id
  subnet_id      = aws_subnet.prv_sub1.id
}

# Create private route table for prv sub2

resource "aws_route_table" "prv_sub2_rt" {
  count  = "1"
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway_2[count.index].id
  }
  tags = {
    Project = "practical-assignment"
    Name = "private subnet2 route table"
  }
}
# Create route table association betn prv sub2 & NAT GW2

resource "aws_route_table_association" "pri_sub2_to_natgw1" {
  count          = "1"
  route_table_id = aws_route_table.prv_sub2_rt[count.index].id
  subnet_id      = aws_subnet.prv_sub2.id
}


# Create security group for load balancer


# Create Security Group for the Bastion Host aka Jump Box
resource "aws_security_group" "ssh-security-group" {
  name        = "SSH Security Group"
  description = "Enable SSH access on Port 22"
  vpc_id      = aws_vpc.main.id
  
ingress {
   description      = "SSH Access"
   from_port        = 22
   to_port          = 22
   protocol         = "tcp"
   cidr_blocks      = ["${var.ssh-location}"]
}
egress {
   from_port        = 0
   to_port          = 0
   protocol         = "-1"
   cidr_blocks      = ["0.0.0.0/0"]
}
    tags   = {
    Name = "SSH Security Group"
    Project = "practical-assignment" 
   }
  }
resource "aws_security_group" "webserver_sg" {
  name        = var.sg_name
  description = var.sg_ws_description
  vpc_id      = aws_vpc.main.id

ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    security_groups = ["${aws_security_group.ssh-security-group.id)"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 tags = {
    Name = var.sg_ws_tagname 
    Project = "practical-assignment"
  }
}


# Generate the SSH keypair that well use to configure the EC2 instance.
# After that, write the private key to a local file and upload the public key to AWS

resource "tls_private_key" "key" {
  algorithm = "RSA"
}
resource "local_file" "private_key" {
  filename          = "TEST.pem"
  sensitive_content = tls_private_key.key.private_key_pem
  file_permission   = "0400"
}
resource "aws_key_pair" "key_pair" {
  key_name   = "TEST"
  public_key = tls_private_key.key.public_key_openssh
}


#Create a new EC2 launch configuration

resource "aws_instance" "ec2_public" {
    ami                    = "ami-026b57f3c383c2eec"
    instance_type               = "${var.instance_type}"
    key_name                    = "${var.key_name}"
    security_groups             = ["${aws_security_group.ssh-security-group.id}"]
    subnet_id                   = "${aws_subnet.pub_sub1.id}"
    associate_public_ip_address = true
    user_data = filebase64("${path.module}/init_webserver.sh")
  #iam_instance_profile = "${aws_iam_instance_profile.some_profile.id}"
    lifecycle {
    create_before_destroy = true
     }
   tags = {
   Name = "EC2-PUBLIC"
   Project = "practical-assignment"
  }
 

# Copies the ssh key file to home dir
# Copies the ssh key file to home dir
  
provisioner "file" {
    source      = "./${var.key_name}.pem"
    destination = "/home/ec2-user/${var.key_name}.pem"
    connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${var.key_name}.pem")
    host        = self.public_ip
    }
 }
     #chmod key 400 on EC2 instance
     provisioner "remote-exec" {
        inline = ["chmod 400 ~/${var.key_name}.pem"]
        connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("${var.key_name}.pem")
        host        = self.public_ip
                 }
          }
}

#Create a new EC2 launch configuration
resource "aws_instance" "ec2_private" {
#name_prefix                 = "terraform-example-web-instance"
     ami                    = "ami-026b57f3c383c2eec"
     instance_type               = "${var.instance_type}"
     key_name                    = "${var.key_name}"
     security_groups             = ["${aws_security_group.webserver_sg.id}"]
     subnet_id                   = "${aws_subnet.pri_sub1.id}"
     associate_public_ip_address = false
     user_data = filebase64("${path.module}/init_webserver.sh")
   lifecycle {
    create_before_destroy = true
   } 
  tags = {
   Name = "EC2-Private"
   Project = "practical-assignment" 
 }
}

# Create Target group

resource "aws_lb_target_group" "TG-tf" {
  name     = "Demo-TargetGroup-tf"
  depends_on = ["aws_vpc.main"]
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
  health_check {
    interval            = 70
    path                = "/"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60 
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}
# Create ALB

resource "aws_lb" "ALB-tf" {
   name              = "Demo-ALG-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver_sg.id]
  subnets            = [aws_subnet.pub_sub1.id,aws_subnet.pub_sub2.id]

  tags = {
	name  = "Demo-AppLoadBalancer-tf"
    	Project = "practical-assignment"
  }
}

# Create ALB Listener 

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ALB-tf.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-tf.arn
  }
}
