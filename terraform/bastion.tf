# Bastion Host Configuration for Secure EC2 Access

resource "aws_security_group" "bastion_sg" {
  count = var.enable_bastion_host ? 1 : 0
  
  name_prefix = "${var.project_name}-bastion-sg-"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  # SSH access from anywhere (restrict in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidr_blocks
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-bastion-sg"
    }
  )
}

# Get latest Amazon Linux 2 AMI (x86_64)
data "aws_ami" "amazon_linux_2_x86" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get latest Amazon Linux 2 AMI (ARM64)
data "aws_ami" "amazon_linux_2_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  count = var.enable_bastion_host ? 1 : 0

  ami                    = can(regex("^t4g", var.bastion_instance_type)) ? data.aws_ami.amazon_linux_2_arm.id : data.aws_ami.amazon_linux_2_x86.id
  instance_type          = var.bastion_instance_type
  key_name               = var.bastion_key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg[0].id]

  # Ensure instance has public IP
  associate_public_ip_address = true

  # Enable detailed monitoring
  monitoring = true

  # User data script for initial setup
  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y

              # Install useful tools
              yum install -y git htop tmux wget curl jq docker

              # Enable and start Docker
              systemctl enable docker
              systemctl start docker

              # Add ec2-user to docker group
              usermod -aG docker ec2-user

              # Install kubectl (detect architecture)
              ARCH=$(uname -m)
              if [ "$ARCH" = "aarch64" ]; then
                KUBECTL_ARCH="arm64"
              else
                KUBECTL_ARCH="amd64"
              fi
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$KUBECTL_ARCH/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/

              # Install AWS CLI
              yum install -y aws-cli

              echo "Bastion host setup completed"
              EOF

  # Tags
  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-bastion"
    }
  )

  # Ensure security group is created before instance
  depends_on = [aws_security_group.bastion_sg]
}

# Elastic IP for bastion (optional, for static IP)
resource "aws_eip" "bastion_eip" {
  count = var.enable_bastion_host && var.bastion_static_eip ? 1 : 0
  
  instance = aws_instance.bastion[0].id
  domain   = "vpc"

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-bastion-eip"
    }
  )

  # Ensure instance is running before assigning EIP
  depends_on = [aws_instance.bastion]
}

# CloudWatch alarm for bastion CPU
resource "aws_cloudwatch_metric_alarm" "bastion_cpu" {
  count = var.enable_bastion_host ? 1 : 0

  alarm_name          = "${var.project_name}-bastion-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 instance CPU utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.bastion[0].id
  }

  tags = merge(
    local.common_tags,
    var.tags
  )
}

# SSM Session Manager preferences (alternative to SSH)
resource "aws_ssm_document" "bastion_session_manager" {
  count = var.enable_bastion_host && var.enable_session_manager ? 1 : 0

  name          = "${var.project_name}-bastion-session-manager"
  document_type = "Session"

  content = <<DOC
  {
    "schemaVersion": "1.0",
    "description": "Session Manager preferences for bastion host",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "",
      "s3KeyPrefix": "",
      "s3EncryptionEnabled": false,
      "cloudWatchLogGroupName": "/aws/sessionmanager/${var.project_name}-bastion",
      "cloudWatchEncryptionEnabled": false,
      "idleSessionTimeout": "20"
    }
  }
  DOC
}
