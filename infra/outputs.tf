output "kubectl_environment" {
   value = "gcloud container clusters get-credentials ${var.tag_prefix}-gke-cluster --region ${var.gcp_region}"
}

output "cluster-name" {
   value = google_container_cluster.primary.name 
}

output "prefix" {
  value = var.tag_prefix
}

output "gcp_region" {
  value = var.gcp_region
}

output "gcp_project" {
  value = var.gcp_project
}

output "gcp_location" {
  value = var.gcp_location
}

output "pg_dbname" {
  value = google_sql_database.tfe-db.name
}

output "pg_user" {
  value = "admin-tfe"
}

output "pg_password" {
  value = var.rds_password
  sensitive = true
}

output "pg_address" {
  value = google_sql_database_instance.instance.private_ip_address
}

output "redis_host" {
  value = google_redis_instance.cache.host
}

output "redis_port" {
  value =  google_redis_instance.cache.port
}

output "google_bucket" {
  value = "${var.tag_prefix}-bucket"
}
