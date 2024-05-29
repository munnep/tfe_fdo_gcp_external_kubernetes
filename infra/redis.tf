resource "google_redis_instance" "cache" {
  name           = "memory-cache"
  memory_size_gb = 1

  authorized_network = google_compute_network.tfe_vpc.id
  auth_enabled       = false
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  depends_on         = [google_service_networking_connection.private_vpc_connection]
}

