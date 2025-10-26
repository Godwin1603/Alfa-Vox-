output "gke_cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.alfavox_cluster.name  # Matches resource name in main.tf
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.alfavox_cluster.endpoint
}

output "gke_cluster_region" {
  description = "GKE Cluster Region"
  value       = google_container_cluster.alfavox_cluster.location
}