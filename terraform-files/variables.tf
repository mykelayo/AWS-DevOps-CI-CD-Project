# AWS Configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2"
  type        = string
  default     = "ami-02dfbd4ff395f2a1b" # Amazon Linux 2 in us-east-1
}

variable "key_name" {
  description = "Name of existing EC2 key pair"
  type        = string
  default     = "awsops"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 12
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp2"
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
  default     = "" # Use default VPC
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "aws-devops-platform"
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.29"
}

variable "pod_network_cidr" {
  description = "Pod network CIDR for Calico"
  type        = string
  default     = "10.244.0.0/16"
}

# Jenkins Configuration
variable "jenkins_version" {
  description = "Jenkins LTS version"
  type        = string
  default     = "latest"
}

# Trivy Configuration
variable "trivy_version" {
  description = "Trivy version"
  type        = string
  default     = "v0.69.3"
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "aws-devops-platform"
  }
}
