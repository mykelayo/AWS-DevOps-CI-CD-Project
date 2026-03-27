aws_region   = "us-east-1"
environment  = "dev"
project_name = "aws-devops-platform"

# Instance configuration
instance_type    = "t3.small"
key_name         = "awsops"
root_volume_size = 16

# Kubernetes configuration
kubernetes_version = "v1.29"
pod_network_cidr   = "10.244.0.0/16"

# Trivy version
trivy_version = "v0.69.3"

# Tags
tags = {
  ManagedBy   = "Terraform"
  Environment = "dev"
  Project     = "devops-platform"
  Team        = "DevOps"
}
