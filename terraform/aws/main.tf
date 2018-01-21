terraform {
  backend "s3" {
    bucket  = "s3-terraform-state.stedel.it"
    key     = "datalab/aws.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

variable "instance_type" {
    description = "AWS instance type"
    default = "t2.micro"
}

variable "provisioner_key" {
    description = "The file path containing ssh keys"
    default = "datalab-provisioner"
}

variable "provisioner_key_file" {
    description = "Private key file path for the provisioner_user"
    default = "~/datalab-provisioner.pem"
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    default = 8000
}

# output "instance_dns_name" {
#     value = "${aws_instance.jupyterhub.public_dns}"
# }

provider "aws" {
    region = "us-east-1"
}

data "aws_ami" "ubuntu14" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

data "aws_ami" "ubuntu16" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ubuntu14" {
    ami = "${data.aws_ami.ubuntu14.id}"
    instance_type = "${var.instance_type}"
    key_name = "${var.provisioner_key}"
    security_groups = ["${aws_security_group.jupyterhub.name}"]

    provisioner "file" {
        source      = "terraform/aws/prepare.sh"
        destination = "/tmp/prepare.sh"

        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file(var.provisioner_key_file)}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo bash /tmp/prepare.sh",
        ]

        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file(var.provisioner_key_file)}"
        }
    }

    tags {
      Role = "jupyterhub"
      Env = "env1"
    }
}

resource "aws_instance" "ubuntu16" {
    ami = "${data.aws_ami.ubuntu16.id}"
    instance_type = "${var.instance_type}"
    key_name = "${var.provisioner_key}"
    security_groups = ["${aws_security_group.jupyterhub.name}"]

    provisioner "file" {
        source      = "prepare.sh"
        destination = "/tmp/prepare.sh"

        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file(var.provisioner_key_file)}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo bash /tmp/prepare.sh",
        ]

        connection {
            type     = "ssh"
            user     = "ubuntu"
            private_key = "${file(var.provisioner_key_file)}"
        }
    }

    tags {
      Role = "jupyterhub"
      Env = "env1"
    }
}

resource "aws_security_group" "jupyterhub" {
    name = "jupyterhub-sg"

    ingress {
        from_port = "${var.server_port}"
        to_port = "${var.server_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}