provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "instance" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${var.subnet}"
  key_name      = "dima2"
  user_data     = "${data.template_file.script.rendered}"
  tags = {
    Name      = "EFS_new"
    Terraform = "true"
  }

  volume_tags = {
    Name      = "EFS_TEST_ROOT"
    Terraform = "true"
  }
  vpc_security_group_ids = [aws_security_group.allow_http_EFS_SSH.id]

  /*  connection {
    type = "ssh"
    user = "ec2-user"
    /*private_key = file("~/dima2.pem")
    password = "${var.password}"
    host     = self.public_ip
  }
  provisioner "file" {
    source      = "./authorized_keys"
    destination = "/home/ec2-user/.ssh/authorized_keys"*/
  connection {
    type = "ssh"
    user = "ec2-user"
    /*private_key = "${file("./dima2.pem")}"
    host_key    = "${file("./dima2.pub")}"*/
    host = self.public_ip
    /*agent       = "true"*/
    timmeout = "2m"
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token   = "EFS Shared Data"
  performance_mode = "generalPurpose"
  tags = {
    Name = "EFS Shared Data"
  }
}
resource "aws_efs_mount_target" "efs" {
  file_system_id = "${aws_efs_file_system.efs.id}"
  subnet_id      = "${var.subnet}"
}
data "template_file" "script" {
  template = "${file("script.tpl")}"
  vars = {
    efs_id = "${aws_efs_file_system.efs.id}"
  }
}

resource "aws_key_pair" "dima2" {
  key_name   = "dima2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1KJNpi6mKA8wOTRxIroSZytjxI2i7VCJ9AS0vP7lSC7WlEELkrFIJPxaTARBd8Q2bUZs53q6OyoU704nK0eBxVBRJKtgy+3ngyZ+dKLEMeq0MzokbRyGoHZT3M/vmdVEhbP7+AHCFpYDs49f559f8pv8pxru3Z1Bv7ytXSqRefqhBG6V6QEc+ZKa7FoF5Je+QM5TwE4LXXREsDvDDIuv30WMou9dH+5wptMj++5DufnL5ssnzH5xjsn6QBObpciqVn9OVyFLWL7SWkFS3yFR1i9dN+JKUZ5DW/s0v+PagEsNxIkaQ3eW08KYcAcKKWpWxnVnkvX5yl7C9ImwL6Mvv dima2"
}

/*data "local_file" "dima2" {
  filename = "${path.module}/dima2.pem"
}*/

resource "aws_security_group" "allow_http_EFS_SSH" {
  name        = "allow_http_EFS_SSH"
  description = "Allow http inbound traffic"
  /*vpc_id      = "${aws_vpc.main.id}"*/

  dynamic "ingress" {
    for_each = ["80", "22", "2049"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

variable "ami" {
  default = "ami-01d025118d8e760db"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "AWS_REGION" {
  default = "us-west-1"
}
variable "subnet" {
  default = "subnet-b9191487"
}

/*variable "root_password" {}*/

variable "host" {
  type    = string
  default = "test-efs"
}
