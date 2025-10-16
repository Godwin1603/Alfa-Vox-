output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.alfavox_vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.alfavox_subnet.id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.alfavox_cluster.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.alfavox_cluster.endpoint
}
