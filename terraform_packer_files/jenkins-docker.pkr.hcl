packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.0"
    }
  }
}

source "amazon-ebs" "jenkins" {
  region        = "us-east-1"
  instance_type = "t2.medium"
  source_ami    = "ami-0cf10cdf9fcd62d37"
  ssh_username  = "ec2-user"

  ami_name = "jenkins-docker-ami-{{timestamp}}"
}

build {
  sources = ["source.amazon-ebs.jenkins"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",

      "sudo yum install git -y",
      "sudo yum install java-17-amazon-corretto -y",
      "sudo yum install maven -y",

      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",

      "sudo yum install docker -y",
      "sudo systemctl enable docker",

      "sudo usermod -aG docker jenkins"
    ]
  }
}