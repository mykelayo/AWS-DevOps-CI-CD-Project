# SERVER1: 'MASTER-SERVER' (with Jenkins, Maven, Docker, Ansible, Trivy)
# 1: CREATING A SECURITY GROUP FOR JENKINS SERVER
resource "aws_security_group" "jenkins_sg" {
  name = "jenkins-sg"
  description = "Allow SSH, HTTP, HTTPS, 8080 for Jenkins & Maven"

  # SSH Inbound Rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH Outbound Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2: CREATE AN JENKINS EC2 INSTANCE USING EXISTING PEM KEY
resource "aws_instance" "master" {
  ami                    = "ami-02dfbd4ff395f2a1b"
  instance_type          = "t3.small"
  key_name               = "awsops"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  root_block_device {
    volume_size = 16
    volume_type = "gp2"
  }

  tags = {
    Name = "MASTER-SERVER"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    yum update -y

    # Install core tools
    yum install -y git docker java-17-amazon-corretto maven

    # Start Docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    usermod -aG docker jenkins || true

    # Install Jenkins
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins

    # Install Trivy (latest stable method)
    rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.69.3/trivy\_0.69.3\_Linux-64bit.rpm
    # Install Ansible properly (Amazon Linux compatible)
    amazon-linux-extras install ansible2 -y || yum install -y ansible

  EOF
}

# 3: OUTPUT PUBLIC IP OF EC2 INSTANCE
output "ACCESS_YOUR_JENKINS_HERE" {
  value = "http://${aws_instance.master.public_ip}:8080"
}

output "Jenkins_Initial_Password" {
  value = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}

# 4: OUTPUT PUBLIC IP OF EC2 INSTANCE
output "MASTER_SERVER_PUBLIC_IP" {
  value = aws_instance.master.public_ip
}

# 5: OUTPUT PRIVATE IP OF EC2 INSTANCE
output "MASTER_SERVER_PRIVATE_IP" {
  value = aws_instance.master.private_ip
}