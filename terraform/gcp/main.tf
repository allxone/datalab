terraform {
  backend "s3" {
    bucket  = "s3-terraform-state.stedel.it"
    key     = "datalab/gcp.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

variable "instance_type" {
    description = "GCP machine type"
    default = "f1-micro"
}

variable "provisioner_key" {
    description = "The file path containing ssh keys"
    default = "datalab-provisioner"
}

variable "provisioner_key_file" {
    description = "Private key file path for the provisioner_user"
    default = "security/datalab-provisioner.pem"
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    default = 8000
}

// Configure the Google Cloud provider
provider "google" {
  credentials = "${file("security/gcp-datalab.json")}"
  project     = "datalab-192808"
  region      = "us-central1"
}

# Provisioner access is granted by inherited project metadata keys 
resource "google_compute_instance" "ubuntu14" {
    name = "ubuntu14"
    machine_type = "${var.instance_type}"
    zone         = "us-central1-a"
    
    boot_disk {
        initialize_params {
            image = "ubuntu-1404-trusty-v20150316"
        }
    }

    network_interface {
        network = "default"
        access_config {}
    }

    provisioner "file" {
        source      = "terraform/aws/prepare.sh"
        destination = "/tmp/prepare.sh"

        connection {
            type     = "ssh"
            user     = "datalab-provisioner"
            private_key = "${file(var.provisioner_key_file)}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo bash /tmp/prepare.sh",
        ]

        connection {
            type     = "ssh"
            user     = "datalab-provisioner"
            private_key = "${file(var.provisioner_key_file)}"
        }
    }

    labels {
      role = "jupyterhub"
      env = "env1"
    }
}