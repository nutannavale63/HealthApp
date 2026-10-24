output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.eks.cluster_iam_role_arn
}

output "oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "node_group_iam_role_arn" {
  description = "EKS node group IAM role ARN"
  value       = module.eks.eks_managed_node_groups["main"].iam_role_arn
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.bbhealthapp_db.endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.bbhealthapp_db.id
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.bbhealthapp_db.port
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for repo in aws_ecr_repository.bbhealthapp_repos : repo.name => repo.repository_url }
}

# Bastion Host Outputs
output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = var.enable_bastion_host ? aws_instance.bastion[0].public_ip : null
}

output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = var.enable_bastion_host ? aws_instance.bastion[0].id : null
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = var.enable_bastion_host ? "ssh -i ~/.ssh/bbhealthapp/${var.bastion_key_name} ec2-user@${aws_instance.bastion[0].public_ip}" : null
}
