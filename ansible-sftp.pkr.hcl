variable "aws_profile" {}

variable "current_version" {
  default = "0-1-1"
}

variable "region" {
  default = "eu-central-1"
}


source "amazon-ebs" "ubuntu" {
    profile = "${var.aws_profile}"
    ami_name = "packer-ansible-sftp-${var.current_version}"
    instance_type = "t2.micro"
    region = "${var.region}"

    source_ami_filter {
        filters {
          virtualization-type = "hvm"
          name =  "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"
          root-device-type = "ebs"
        }
        owners = ["099720109477"]
        most_recent = true
    }

    communicator = "ssh"
    ssh_username = "ubuntu"
    ssh_keypair_name = "packer_hcl_demo_debug_key"
    ssh_private_key_file = "packer_hcl_demo_debug_key.pem"
    # remove temporary keys when -debug, using above custom key
    ssh_clear_authorized_keys = true
    associate_public_ip_address = true
    vpc_id = "vpc-4da57326"
    subnet_id = "subnet-c943d8a2"

    tags {
      Name = "packer-ansible-sftp-${var.current_version}"
    }
}

# A build starts sources and runs provisioning steps on those sources.
build {
  sources = [
    # there can be multiple sources per build
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sleep 30",
      "sudo apt update",
      "sudo apt-get install python3",
      "sudo apt install --yes software-properties-common",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible"
    ]
  }

  provisioner "ansible-local" {
    playbook_file = "./ansible/playbook.yaml"
    inventory_file = "./ansible/inventory"
    galaxy_file = "./ansible/requirements.yaml"
    playbook_dir = "./ansible"
  }

  # Uncomment for builder -debug mode
  provisioner "shell" {
    inline = [
      "sleep 3"
    ]
  }

  # post-processors work too, example: `post-processor "shell-local" {}`.
}
