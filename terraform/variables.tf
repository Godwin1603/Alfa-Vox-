variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "alfavox-cluster"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "alfavox-node-group"
}
