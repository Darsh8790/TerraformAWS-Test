# Defining Region
variable "aws_region" {
  default = "ap-south-1"
}

# Defining CIDR Block for VPC
variable "vpc_cidr" {
  default = "30.0.0.0/16"
}

# Defining CIDR Block for Subnet
variable "subnet_cidr" {
  default = "30.0.1.0/24"
}

# Defining CIDR Block for 2d Subnet
variable "subnet1_cidr" {
  default = "30.0.2.0/24"
}


# Defining Public Key
variable "public_key" {
  default = "tests.pub"
}

# Defining Private Key
variable "private_key" {
  default = "tests.pem"
}

# Definign Key Name for connection
variable "key_name" {
  default = "tests"
  description = "Desired name of AWS key pair"
}



# Defining AMI
variable "ami" {
 # default = "ami-01c1009f059c6e694"
 # default = "ami-07050b42151ef470c"
  default = "ami-0745276ff99a9e05d"
}

# Defining Instace Type
variable "instancetype" {
  default = "t3.medium"
}

# Defining Master count
variable "master_count" {
  default = 1
}
[ec2-user@ip-10-10-1-181 ~]$
[ec2-user@ip-10-10-1-181 ~]$
[ec2-user@ip-10-10-1-181 ~]$  cat main.tf
# Configure and downloading plugins for aws
provider "aws" {
  region     = "${var.aws_region}"
}

# Creating VPC
resource "aws_vpc" "demovpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "Demo VPC"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "demogateway" {
  vpc_id = "${aws_vpc.demovpc.id}"
}

# Grant the internet access to VPC by updating its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.demovpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.demogateway.id}"
}

# Creating 1st subnet
resource "aws_subnet" "demosubnet" {
  vpc_id                  = "${aws_vpc.demovpc.id}"
  cidr_block             = "${var.subnet_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Demo subnet"
  }
}

# Creating 2nd subnet
resource "aws_subnet" "demosubnet1" {
  vpc_id                  = "${aws_vpc.demovpc.id}"
  cidr_block             = "${var.subnet1_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Demo subnet 1"
  }
}

# Creating Security Group
resource "aws_security_group" "demosg" {
  name        = "Demo Security Group"
  description = "Demo Module"
  vpc_id      = "${aws_vpc.demovpc.id}"

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating key pair
data "aws_key_pair" "bhs-nginx-key" {
  key_name   = "bhs-nginx-key"
  include_public_key = true
}

# Creating EC2 Instance
resource "aws_instance" "demoinstance" {

  # AMI based on region
  ami = "${var.ami}"

  # Launching instance into subnet
  subnet_id = "${aws_subnet.demosubnet.id}"

  # Instance type
  instance_type = "${var.instancetype}"

  # Count of instance
  count= "${var.master_count}"

  # SSH key that we have generated above for connection
  key_name = "${data.aws_key_pair.bhs-nginx-key.key_name}"

  # Attaching security group to our instance
  vpc_security_group_ids = ["${aws_security_group.demosg.id}"]

  # Attaching Tag to Instance
  tags = {
    Name = "Search-Head-${count.index + 1}"
  }



  # SSH into instance
  connection {

    # Host name
    host = self.public_ip
    # The default username for our AMI
    user = "ubuntu"
    # Private key for connection
    private_key = "${file(var.private_key)}"
    # Type of connection
    type = "ssh"
  }

  # Installing splunk on newly created instance
  provisioner "remote-exec" {
    inline = [
    #  "A=`(sudo docker ps -a |awk '{print $1}'|grep -Ev CONTAINE)`",
    #  "sudo docker rm $A",
      "sudo apt-get update",
      "sudo apt install docker.io -y",
      "sudo snap install docker",
      "sudo docker --version",
      "sudo docker pull nginx",
    #  "sudo docker run --name docker-nginx -p 80:80 -d nginx"
       "sudo docker run --name docker-nginxibhs -p 80:80 -d -v ~/docker-nginx/bhs:/usr/share/nginx/html nginx"
  ]
 }
}
