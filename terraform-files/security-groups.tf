# Get default VPC if no VPC ID is specified
data "aws_vpc" "default" {
  default = true
}

# Security Group for Jenkins/Master Server
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg-${var.environment}"
  description = "Security group for Jenkins, Maven, Docker, Ansible, Trivy server"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  tags = merge(var.tags, {
    Name = "jenkins-sg-${var.environment}"
  })
}

# Security Group for Kubernetes Node Server
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg-${var.environment}"
  description = "Security group for Kubernetes cluster - Control Plane & Worker Nodes"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  tags = merge(var.tags, {
    Name = "k8s-sg-${var.environment}"
  })
}

# Jenkins Security Group Rules
resource "aws_security_group_rule" "jenkins_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.jenkins_sg.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "jenkins_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.jenkins_sg.id
  description       = "HTTP web traffic"
}

resource "aws_security_group_rule" "jenkins_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.jenkins_sg.id
  description       = "HTTPS web traffic"
}

resource "aws_security_group_rule" "jenkins_port_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.jenkins_sg.id
  description       = "Jenkins web interface"
}

resource "aws_security_group_rule" "jenkins_port_8081" {
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.jenkins_sg.id
  description       = "Jenkins alternative port"
}

# Kubernetes Security Group Rules
resource "aws_security_group_rule" "k8s_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.k8s_sg.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "k8s_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.k8s_sg.id
  description       = "HTTP web traffic"
}

resource "aws_security_group_rule" "k8s_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.k8s_sg.id
  description       = "HTTPS web traffic"
}

resource "aws_security_group_rule" "k8s_api_server" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
  description       = "Kubernetes API Server"
}

resource "aws_security_group_rule" "k8s_dashboard" {
  type              = "ingress"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
  description       = "Kubernetes Dashboard / Metrics Server"
}

resource "aws_security_group_rule" "k8s_kubelet" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
  description       = "Kubelet API"
}

resource "aws_security_group_rule" "k8s_nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
  description       = "Kubernetes NodePort services"
}

# Allow inter-node communication for Kubernetes
resource "aws_security_group_rule" "k8s_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.k8s_sg.id
  description       = "Allow all traffic within the security group"
}

# Egress Rules for both security groups
resource "aws_security_group_rule" "jenkins_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_sg.id
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "k8s_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_sg.id
  description       = "Allow all outbound traffic"
}
