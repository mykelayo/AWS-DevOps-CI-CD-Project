# Master Server (Jenkins)
resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = merge(var.tags, {
    Name = "MASTER-SERVER-${var.environment}"
    Role = "Jenkins-Master"
  })

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    yum update -y

    # Install core tools
    yum install -y git docker java-17-amazon-corretto maven wget

    # Start Docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    usermod -aG docker jenkins 2>/dev/null || true

    # Install Jenkins (latest LTS)
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins

    # Install Trivy
    wget https://github.com/aquasecurity/trivy/releases/download/${var.trivy_version}/trivy_${replace(var.trivy_version, "v", "")}_Linux-64bit.rpm
    rpm -ivh trivy_${replace(var.trivy_version, "v", "")}_Linux-64bit.rpm
    rm -f trivy_${replace(var.trivy_version, "v", "")}_Linux-64bit.rpm

    # Install Ansible
    amazon-linux-extras install ansible2 -y || yum install -y ansible

    # Add Jenkins to Docker group
    while ! getent group docker; do sleep 2; done
    usermod -aG docker jenkins

    # Restart Jenkins to apply group changes
    systemctl restart jenkins

    # Output Jenkins initial password
    echo "========================================="
    echo "Jenkins initial admin password:"
    sleep 10
    cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Password file not ready yet"
    echo "========================================="
  EOF
}

# Kubernetes Node Server (Control Plane)
resource "aws_instance" "node" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = merge(var.tags, {
    Name = "K8S-CONTROL-PLANE-${var.environment}"
    Role = "Kubernetes-Control-Plane"
  })

  user_data = <<-EOF
    #!/bin/bash
    set -e

    yum update -y

    # Disable swap
    swapoff -a
    sed -i '/swap/d' /etc/fstab

    # Kernel modules
    modprobe br_netfilter
    cat <<EOT > /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    EOT
    sysctl --system

    # Install containerd
    yum install -y containerd
    systemctl enable containerd
    systemctl start containerd
    
    # Configure containerd
    mkdir -p /etc/containerd
    containerd config default > /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl restart containerd

    # Kubernetes repo
    cat <<EOT > /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://pkgs.k8s.io/core:/stable:/${var.kubernetes_version}/rpm/
    enabled=1
    gpgcheck=1
    gpgkey=https://pkgs.k8s.io/core:/stable:/${var.kubernetes_version}/rpm/repodata/repomd.xml.key
    EOT

    # Install K8s
    yum install -y kubelet kubeadm kubectl
    systemctl enable kubelet

    # Init cluster
    kubeadm init --pod-network-cidr=${var.pod_network_cidr}

    # Configure kubectl
    mkdir -p /home/ec2-user/.kube
    cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
    chown ec2-user:ec2-user /home/ec2-user/.kube/config

    # Install Calico network
    su - ec2-user -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/${var.trivy_version}/manifests/calico.yaml"

    # Wait for Calico to be ready
    sleep 30
    
    # Allow scheduling on control plane
    su - ec2-user -c "kubectl taint nodes --all node-role.kubernetes.io/control-plane-"
  EOF

  depends_on = [aws_instance.master]
}
