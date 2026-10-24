#!/bin/bash

# BBHealthApp - Jenkins Server Setup Script
# This script installs and configures Jenkins with all required tools for CI/CD automation

set -e

echo "========================================="
echo "Jenkins Server Setup for BBHealthApp"
echo "========================================="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS $VERSION"

# Update system packages
echo "Updating system packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get update -y
    sudo apt-get upgrade -y
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum update -y
fi

# Install Java (Jenkins requires Java 11 or 17)
echo "Installing Java 17..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get install -y openjdk-17-jdk
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y java-17-amazon-corretto
fi

# Set JAVA_HOME
echo "Setting JAVA_HOME..."
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install Docker
echo "Installing Docker..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Add Jenkins user to docker group
echo "Adding Jenkins user to docker group..."
sudo usermod -aG docker jenkins || sudo usermod -aG docker $USER

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Terraform
echo "Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

# Install Git
echo "Installing Git..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get install -y git
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y git
fi

# Install Jenkins
echo "Installing Jenkins..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null

    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y jenkins
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
      https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum install -y jenkins
fi

# Start and enable Jenkins
echo "Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install additional useful tools
echo "Installing additional tools..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get install -y \
        unzip \
        jq \
        curl \
        wget \
        vim \
        net-tools \
        python3 \
        python3-pip
elif [ "$OS" = "amzn" ] || [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y \
        unzip \
        jq \
        curl \
        wget \
        vim \
        net-tools \
        python3 \
        python3-pip
fi

# Install Python packages
echo "Installing Python packages..."
pip3 install --upgrade pip
pip3 install awscli boto3

# Configure Docker to start on boot
echo "Configuring Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Verify installations
echo "========================================="
echo "Verifying installations..."
echo "========================================="
echo "Java version:"
java -version
echo ""
echo "Docker version:"
docker --version
echo ""
echo "AWS CLI version:"
aws --version
echo ""
echo "kubectl version:"
kubectl version --client
echo ""
echo "Helm version:"
helm version
echo ""
echo "Terraform version:"
terraform version
echo ""
echo "Git version:"
git --version
echo ""
echo "Jenkins status:"
sudo systemctl status jenkins --no-pager || echo "Jenkins service may not be running yet"

# Display Jenkins initial admin password
echo "========================================="
echo "Jenkins Setup Complete!"
echo "========================================="
echo "Jenkins is installed and running."
echo ""
echo "To get the initial admin password, run:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "Access Jenkins at: http://$(curl -s ifconfig.me):8080"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo "1. Access Jenkins web interface"
echo "2. Install recommended plugins"
echo "3. Create admin user"
echo "4. Install required plugins:"
echo "   - Pipeline"
echo "   - Git"
echo "   - Docker Pipeline"
echo "   - AWS Steps"
echo "   - Credentials Binding"
echo "   - Blue Ocean (optional)"
echo "5. Configure AWS credentials"
echo "6. Create pipeline job with Jenkinsfile"
echo "========================================="
