resource "google_container_cluster" "primary" {
  name     = "${var.tag_prefix}-gke-cluster"
  location = var.gcp_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection = false

  network = google_compute_network.tfe_vpc.name
  subnetwork = google_compute_subnetwork.tfe_subnet.name
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       =  "${var.tag_prefix}-gke-nodes"
  location   = var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.service_account.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}