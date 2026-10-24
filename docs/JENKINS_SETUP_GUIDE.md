# BBHealthApp - Complete Jenkins Automation Setup Guide

This guide provides step-by-step instructions to set up a fully automated Jenkins CI/CD pipeline for the BBHealthApp project.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Jenkins Server Setup](#jenkins-server-setup)
4. [Jenkins Configuration](#jenkins-configuration)
5. [Pipeline Job Setup](#pipeline-job-setup)
6. [AWS Credentials Configuration](#aws-credentials-configuration)
7. [Webhook Configuration](#webhook-configuration)
8. [Pipeline Execution](#pipeline-execution)
9. [Monitoring and Notifications](#monitoring-and-notifications)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Jenkins automation for BBHealthApp includes:

- **Infrastructure as Code**: Terraform provisioning of AWS resources
- **Container Build**: Docker image builds for all microservices
- **Registry Management**: Push/pull from AWS ECR
- **Kubernetes Deployment**: Helm-based deployment to EKS
- **Testing**: Automated health checks and integration tests
- **Rollback**: Automatic rollback on failure
- **Parallel Execution**: Concurrent builds for faster CI/CD

---

## Prerequisites

### AWS Resources
- AWS Account with appropriate permissions
- Existing EKS cluster (or let Terraform create one)
- RDS database instance
- ECR repositories (or let Terraform create them)

### Required Permissions
The Jenkins IAM user/role needs permissions for:
- EKS cluster access
- ECR push/pull
- EC2 (for infrastructure provisioning)
- IAM (for role creation)
- S3 (for Terraform state)
- RDS (for database management)

### Tools Required
- Git
- Docker
- AWS CLI
- kubectl
- Helm
- Terraform

---

## Jenkins Server Setup

### Option 1: Automated Setup (Recommended)

Use the provided setup script to install Jenkins and all required tools:

```bash
# Clone the repository
git clone https://github.com/Ishikapbhatt/healthapp-aws.git
cd healthapp-aws

# Run the setup script
chmod +x scripts/setup-jenkins-server.sh
sudo ./scripts/setup-jenkins-server.sh
```

The script will install:
- Java 17
- Jenkins
- Docker
- AWS CLI
- kubectl
- Helm
- Terraform
- Git
- Additional utilities

### Option 2: Manual Setup

#### 1. Install Java 17

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk
```

**Amazon Linux/CentOS:**
```bash
sudo yum install -y java-17-amazon-corretto
```

#### 2. Install Jenkins

**Ubuntu/Debian:**
```bash
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo apt-key add -
echo deb https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get update
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

**Amazon Linux/CentOS:**
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

#### 3. Install Docker

```bash
# Ubuntu/Debian
sudo apt-get install -y docker.io

# Amazon Linux/CentOS
sudo yum install -y docker

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER
```

#### 4. Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### 5. Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### 6. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 7. Install Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform
```

### Get Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins at: `http://<your-server-ip>:8080`

---

## Jenkins Configuration

### Step 1: Unlock Jenkins

1. Open `http://<jenkins-server-ip>:8080` in your browser
2. Enter the initial admin password
3. Click "Install suggested plugins"

### Step 2: Create Admin User

1. Create your admin user
2. Save and continue
3. Click "Start using Jenkins"

### Step 3: Install Required Plugins

Go to **Manage Jenkins** → **Plugins** → **Available** and install:

1. **Pipeline** - For pipeline as code
2. **Git** - For Git integration
3. **Docker Pipeline** - For Docker operations
4. **AWS Steps** - For AWS CLI integration
5. **Credentials Binding** - For credential management
6. **Blue Ocean** (optional) - For better visualization
7. **GitHub** - For GitHub integration
8. **Kubernetes CLI** - For kubectl integration
9. **Terraform** - For Terraform integration

### Step 4: Configure Global Tool Configuration

Go to **Manage Jenkins** → **Global Tool Configuration**

#### AWS CLI
- Name: `AWSCLI`
- Install automatically: Yes

#### Docker
- Name: `Docker`
- Install automatically: Yes

#### Helm
- Name: `Helm`
- Install automatically: Yes

#### Terraform
- Name: `Terraform`
- Install automatically: Yes

### Step 5: Configure System Properties

Go to **Manage Jenkins** → **Configure System**

#### Environment Variables
Add the following environment variables:

```
AWS_REGION = us-west-2
JAVA_HOME = /usr/lib/jvm/java-17-openjdk-amd64
PATH = $JAVA_HOME/bin:$PATH
```

---

## Pipeline Job Setup

### Step 1: Create New Pipeline Job

1. Click **New Item**
2. Enter **Item name**: `bbhealthapp-cicd-pipeline`
3. Select **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

#### General
- Description: `BBHealthApp CI/CD Pipeline - Automated deployment to EKS`

#### Pipeline Configuration
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/Ishikapbhatt/healthapp-aws.git`
- **Credentials**: (if private repo, add Git credentials)
- **Branches to build**: `*/main`
- **Script Path**: `Jenkinsfile`
- **Lightweight checkout**: Checked

#### Build Triggers
- **GitHub hook trigger for GITScm polling**: Checked (if using GitHub)
- **Poll SCM**: Schedule: `H/5 * * * *` (poll every 5 minutes)

#### Pipeline Parameters
The Jenkinsfile includes the following parameters:

- **ENVIRONMENT**: dev, staging, prod (default: dev)
- **REBUILD_INFRA**: true/false (default: false)
- **RUN_TESTS**: true/false (default: true)
- **SKIP_DEPLOY**: true/false (default: false)

### Step 3: Save Configuration

Click **Save** to save the pipeline configuration.

---

## AWS Credentials Configuration

### Step 1: Create AWS IAM User

1. Go to AWS IAM Console
2. Create a new user for Jenkins
3. Attach the following policy (or create a custom one):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ecr:*",
        "ec2:*",
        "iam:*",
        "s3:*",
        "rds:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

4. Create access key and secret key
5. Save the credentials securely

### Step 2: Add AWS Credentials to Jenkins

1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. Select **AWS Credentials**
4. Fill in:
   - **ID**: `aws-credentials`
   - **Access Key ID**: Your AWS access key
   - **Secret Access Key**: Your AWS secret key
   - **Description**: AWS credentials for BBHealthApp deployment
5. Click **Create**

### Step 3: Add Git Credentials (if private repo)

1. Click **Add Credentials**
2. Select **Username with password**
3. Fill in:
   - **ID**: `git-credentials`
   - **Username**: Your Git username
   - **Password**: Your Git personal access token
4. Click **Create**

---

## Webhook Configuration

### GitHub Webhook Setup

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks**
3. Click **Add webhook**
4. Configure:
   - **Payload URL**: `http://<jenkins-server-ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (optional) Generate a secret token
   - **SSL verification**: Enable if using HTTPS
   - **Events**: Select "Just the push event"
5. Click **Add webhook**

### GitLab Webhook Setup

1. Go to your GitLab project
2. Click **Settings** → **Webhooks**
3. Add webhook:
   - **URL**: `http://<jenkins-server-ip>:8080/project/bbhealthapp-cicd-pipeline`
   - **Trigger**: Push events
   - **Enable SSL verification**: If using HTTPS
4. Click **Add webhook**

### Jenkins Webhook Configuration

1. Go to your pipeline job configuration
2. Under **Build Triggers**, check:
   - **GitHub hook trigger for GITScm polling**
3. Save the configuration

---

## Pipeline Execution

### Manual Build

1. Go to the pipeline job `bbhealthapp-cicd-pipeline`
2. Click **Build with Parameters**
3. Select parameters:
   - **ENVIRONMENT**: Choose dev, staging, or prod
   - **REBUILD_INFRA**: Check to rebuild infrastructure (rarely needed)
   - **RUN_TESTS**: Check to run tests
   - **SKIP_DEPLOY**: Check to build and push only (no deployment)
4. Click **Build**

### Automatic Build

With webhooks configured, the pipeline will automatically trigger on:
- Push to main branch
- Pull request merge to main

### View Pipeline Progress

1. Click on the build number
2. View the stage-by-stage progress
3. Click on each stage to see detailed logs
4. Download logs for offline analysis

### Blue Ocean View (if installed)

1. Click **Open Blue Ocean**
2. Visual representation of pipeline execution
3. Click on stages to see details
4. Better visualization of parallel stages

---

## Monitoring and Notifications

### Build Notifications

#### Email Notifications

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **E-mail Notification**
3. Configure:
   - **SMTP server**: `smtp.gmail.com` (or your SMTP server)
   - **Default user email**: Your email
   - **SMTP port**: 587
   - **Use SSL**: Yes
   - **Use TLS**: Yes
4. Click **Test configuration** to verify
5. Click **Save**

#### Slack Notifications

1. Install the **Slack Notification** plugin
2. Go to **Manage Jenkins** → **Configure System**
3. Scroll to **Slack**
4. Configure:
   - **Team Domain**: Your Slack team
   - **Credential**: Add Slack token
   - **Default Channel**: `#devops` (or your channel)
5. Click **Test Connection**
6. Click **Save**

Add notifications to Jenkinsfile:

```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "✅ Deployment successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "❌ Deployment failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
        )
    }
}
```

### Health Monitoring

The pipeline includes automatic health checks:

1. **Pod Health Check**: Waits for all pods to be ready
2. **Service Health Check**: Verifies services are accessible
3. **Ingress Health Check**: Verifies Load Balancer is accessible
4. **Integration Tests**: Tests application endpoints

View health check results in the "Health Check" stage logs.

---

## Troubleshooting

### Jenkins won't start

```bash
# Check Jenkins status
sudo systemctl status jenkins

# Check logs
sudo tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins
sudo systemctl restart jenkins
```

### Docker permission denied

```bash
# Add Jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### AWS credentials not found

1. Verify credentials are configured in Jenkins
2. Check credentials ID matches in Jenkinsfile
3. Ensure IAM user has required permissions
4. Test AWS CLI: `aws sts get-caller-identity`

### Terraform initialization fails

```bash
# Clear Terraform cache
rm -rf .terraform

# Reinitialize
terraform init
```

### Helm deployment fails

```bash
# Check Helm version
helm version

# List existing releases
helm list -n bbhealthapp

# Check kubeconfig
kubectl config view

# Update Helm repositories
helm repo update
```

### kubectl cannot connect to cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --name bbhealthapp-cluster --region us-west-2

# Test connection
kubectl get nodes
```

### Docker build fails

```bash
# Check Docker daemon
sudo systemctl status docker

# Check disk space
df -h

# Clean Docker cache
docker system prune -a
```

### Pipeline timeout

Increase timeout in Jenkinsfile:

```groovy
helm upgrade --install bbhealthapp ./helm/bbhealthapp \
  --namespace bbhealthapp \
  --timeout 20m  # Increase from 10m to 20m
```

### Rollback on failure

The pipeline automatically rolls back on failure. To manually rollback:

```bash
# Get revision history
helm history bbhealthapp -n bbhealthapp

# Rollback to previous version
helm rollback bbhealthapp -n bbhealthapp
```

---

## Advanced Configuration

### Multi-Environment Deployment

Create separate pipeline jobs for each environment:

- `bbhealthapp-dev-pipeline`
- `bbhealthapp-staging-pipeline`
- `bbhealthapp-prod-pipeline`

Configure each with different parameters and approval gates.

### Approval Gates

Add manual approval for production deployment:

```groovy
stage('Approve Production Deployment') {
    when {
        expression { params.ENVIRONMENT == 'prod' }
    }
    steps {
        input message: 'Deploy to Production?', ok: 'Deploy'
    }
}
```

### Parallel Testing

Run tests in parallel:

```groovy
stage('Run Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'mvn verify'
            }
        }
    }
}
```

### Conditional Deployment

Deploy based on branch:

```groovy
stage('Deploy') {
    when {
        branch 'main'
    }
    steps {
        sh 'helm upgrade --install bbhealthapp ./helm/bbhealthapp'
    }
}
```

---

## Best Practices

1. **Use Pipeline as Code**: Store Jenkinsfile in Git repository
2. **Credential Management**: Never hardcode credentials
3. **Version Control**: Tag releases in Git
4. **Testing**: Run tests before deployment
5. **Monitoring**: Set up notifications for build failures
6. **Rollback**: Always have rollback capability
7. **Security**: Use least privilege IAM policies
8. **Documentation**: Document any custom configurations
9. **Backup**: Backup Jenkins configuration regularly
10. **Updates**: Keep Jenkins and plugins updated

---

## Maintenance

### Backup Jenkins Configuration

```bash
# Backup Jenkins home directory
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins

# Backup to S3
aws s3 cp jenkins-backup-$(date +%Y%m%d).tar.gz s3://backups/jenkins/
```

### Update Jenkins

```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Update Jenkins
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins
sudo systemctl start jenkins
```

### Clean Workspace

Add to Jenkinsfile:

```groovy
post {
    always {
        cleanWs()
    }
}
```

### Clean Docker Images

Add to Jenkinsfile:

```groovy
post {
    always {
        sh 'docker system prune -f'
    }
}
```

---

## Support

For issues or questions:

1. Check Jenkins logs: `/var/log/jenkins/jenkins.log`
2. Check pipeline console output
3. Verify AWS credentials and permissions
4. Check EKS cluster status
5. Jenkins Documentation: https://www.jenkins.io/doc/
6. Helm Documentation: https://helm.sh/docs/
7. AWS Documentation: https://docs.aws.amazon.com/

---

**Happy Automating! 🚀**
