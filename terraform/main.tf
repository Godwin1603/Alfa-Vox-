# terraform/main.tf - Let GKE auto-assign IPs
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.85.0"
    }
  }
}

provider "google" {
  project = "alfa-vox-portfolio"
  region  = "us-central1"
}

# Ultra-minimal GKE cluster - let GKE handle IP allocation
resource "google_container_cluster" "alfavox_cluster" {
  name               = "alfavox-cluster"
  location           = "us-central1-a"  # Single zone only
  initial_node_count = 1                # Only 1 node
  
  # Use default network
  network    = "default"
  subnetwork = "default"

  # Use default node pool
  remove_default_node_pool = false

  # Remove ip_allocation_policy entirely - let GKE auto-assign
  # This will use the minimum required IPs automatically

  # Simple node config
  node_config {
    machine_type = "e2-micro"
    disk_size_gb = 20
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}