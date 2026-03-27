# Jenkins Server Outputs
output "jenkins_server_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.master.public_ip}:8080"
}

output "jenkins_initial_password_command" {
  description = "Command to get Jenkins initial admin password"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.master.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_instance.master.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of Jenkins server"
  value       = aws_instance.master.private_ip
}

# Kubernetes Server Outputs
output "k8s_server_public_ip" {
  description = "Public IP of Kubernetes control plane"
  value       = aws_instance.node.public_ip
}

output "k8s_server_private_ip" {
  description = "Private IP of Kubernetes control plane"
  value       = aws_instance.node.private_ip
}

output "k8s_join_command_command" {
  description = "Command to join worker nodes (run on master first)"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.node.public_ip} 'kubeadm token create --print-join-command'"
}

output "k8s_kubeconfig_command" {
  description = "Command to get kubeconfig for kubectl"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.node.public_ip} 'sudo cat /etc/kubernetes/admin.conf'"
}

# Combined Outputs
output "summary" {
  description = "Deployment summary"
  value       = <<-EOT
    ========================================
    DEPLOYMENT SUMMARY
    ========================================
    
    JENKINS SERVER:
    - URL: http://${aws_instance.master.public_ip}:8080
    - Public IP: ${aws_instance.master.public_ip}
    - Private IP: ${aws_instance.master.private_ip}
    - Initial Password: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.master.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
    
    KUBERNETES CONTROL PLANE:
    - Public IP: ${aws_instance.node.public_ip}
    - Private IP: ${aws_instance.node.private_ip}
    - Join Command: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.node.public_ip} 'kubeadm token create --print-join-command'
    
    ========================================
  EOT
}
