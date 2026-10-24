# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    # Disabled EBS CSI driver temporarily to speed up deployment
    # aws-ebs-csi-driver = {
    #   most_recent = true
    # }
  }

  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name           = var.node_group_name
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      capacity_type = var.enable_spot_instances ? "SPOT" : "ON_DEMAND"

      labels = {
        Environment = var.environment
        Project     = var.project_name
        Architecture = var.node_architecture
      }

      taints = []

      tags = {
        Name = "${var.project_name}-node"
        Architecture = var.node_architecture
      }

      # Use AMI type based on architecture
      ami_type = var.node_architecture == "ARM64" ? "AL2_ARM_64" : "AL2_x86_64"
    }
  }

  # Cluster access entry
  create_iam_role = true

  # Enable IRSA
  enable_irsa = true

  # CloudWatch logging
  cluster_enabled_log_types = var.enable_cloudwatch_logging ? [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ] : []

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks"
    }
  )
}

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.0"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [
    module.eks
  ]
}

# External DNS (optional)
resource "helm_release" "external_dns" {
  count = var.environment == "prod" ? 1 : 0

  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = "kube-system"

  set {
    name  = "aws.credentials.secretKey"
    value = "aws_access_key_id"
  }

  set {
    name  = "aws.credentials.secretKey"
    value = "aws_secret_access_key"
  }

  depends_on = [
    module.eks
  ]
}

# Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  depends_on = [
    module.eks
  ]
}
