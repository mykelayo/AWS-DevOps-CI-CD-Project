# SERVER2: 'NODE-SERVER' (with Docker & Kubernetes)
# 1: CREATING A SECURITY GROUP FOR DOCKER-K8S
# Description: K8s requires ports 22, 80, 443, 6443, 8001, 10250, 30000-32767
resource "aws_security_group" "k8s_sg" {
  name = "k8s-sg"

  ingress { from_port=22 to_port=22 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=443 to_port=443 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=6443 to_port=6443 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=8001 to_port=8001 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=10250 to_port=10250 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=30000 to_port=32767 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }

  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

# 2: CREATE A K8S EC2 INSTANCE USING EXISTING PEM KEY

resource "aws_instance" "node" {
  ami                    = "ami-02dfbd4ff395f2a1b"
  instance_type          = "t3.small"
  key_name               = "awsops"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 16
    volume_type = "gp2"
  }

  tags = {
    Name = "K8S-CONTROL-PLANE"
  }

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
    baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
    enabled=1
    gpgcheck=1
    gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
    EOT

    # Install K8s
    yum install -y kubelet kubeadm kubectl
    systemctl enable kubelet

    # Init cluster
    kubeadm init --pod-network-cidr=10.244.0.0/16

    # Configure kubectl
    mkdir -p /home/ec2-user/.kube
    cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
    chown ec2-user:ec2-user /home/ec2-user/.kube/config

    # Install Calico network
    su - ec2-user -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml"

    # Wait for Calico to be ready
    sleep 30
    
    # Allow scheduling on control plane
    su - ec2-user -c "kubectl taint nodes --all node-role.kubernetes.io/control-plane-"
EOF

# 3: OUTPUT PUBLIC IP OF EC2 INSTANCE
output "node_public_ip" {
  value = aws_instance.node.public_ip
}

# STEP4: OUTPUT PRIVATE IP OF EC2 INSTANCE
output "node_private_ip" {
  value = aws_instance.node.private_ip
}