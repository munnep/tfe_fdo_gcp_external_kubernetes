resource "google_compute_network" "tfe_vpc" {
  name                    = "${var.tag_prefix}-vpc"
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "tfe_subnet" {
  name          = "${var.tag_prefix}-public1"
  ip_cidr_range = cidrsubnet(var.vnet_cidr, 8, 1)
  network       = google_compute_network.tfe_vpc.self_link
}

resource "google_compute_router" "tfe_router" {
  name    = "${var.tag_prefix}-router"
  network = google_compute_network.tfe_vpc.self_link
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.tfe_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "5432", "8201", "6379"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_storage_bucket" "tfe-bucket" {
  name          = "${var.tag_prefix}-bucket"
  location      = var.gcp_location
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_compute_global_address" "private_ip_address" {
  # provider = google-beta

  name          = "tfe-vpc-internal2"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.tfe_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  # provider = google-beta

  network                 = google_compute_network.tfe_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  deletion_policy = "ABANDON"
}


resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name             = "${var.tag_prefix}-database"
  region           = var.gcp_region
  database_version = "POSTGRES_15"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-g1-small" ## possible issue in size
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.tfe_vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }
  deletion_protection = false
}

resource "google_project_iam_binding" "example_storage_admin_binding" {
  project = var.gcp_project
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

# doing it all on bucket permissions
resource "google_service_account" "service_account" {
  account_id   = "${var.tag_prefix}-bucket-test2"
  display_name = "${var.tag_prefix}-bucket-test2"
  project      = var.gcp_project
}

resource "google_service_account_key" "tfe_bucket" {
  service_account_id = google_service_account.service_account.name
}


data "google_project" "project" {
}


# these are for the service account when using auto-pilot GKE
resource "google_storage_bucket_iam_member" "object_viewer_binding" {
  bucket = google_storage_bucket.tfe-bucket.name

  role   = "roles/storage.objectAdmin"
  member = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${data.google_project.project.project_id}.svc.id.goog/subject/ns/terraform-enterprise/sa/terraform-enterprise"
}

resource "google_storage_bucket_iam_member" "object_viewer_binding2" {
  bucket = google_storage_bucket.tfe-bucket.name

  role   = "roles/storage.legacyBucketReader"
  member = "principal://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${data.google_project.project.project_id}.svc.id.goog/subject/ns/terraform-enterprise/sa/terraform-enterprise"
}



# these are for the service account when using non auto-pilot GKE
resource "google_storage_bucket_iam_member" "member-object" {
  bucket = google_storage_bucket.tfe-bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_storage_bucket_iam_member" "member-bucket" {
  bucket = google_storage_bucket.tfe-bucket.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_sql_database" "tfe-db" {
  # provider = google-beta
  name     = "tfe"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "tfeadmin" {
  # provider = google-beta
  name            = "admin-tfe"
  instance        = google_sql_database_instance.instance.name
  password        = var.rds_password
  deletion_policy = "ABANDON"
}
