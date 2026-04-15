terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# -------------------------
# Networks
# -------------------------
resource "google_compute_network" "frontend_vpc" {
  name                    = "vpc-frontend"
  auto_create_subnetworks = false
}

resource "google_compute_network" "backend_vpc" {
  name                    = "vpc-backend"
  auto_create_subnetworks = false
}

# -------------------------
# Subnets
# -------------------------
resource "google_compute_subnetwork" "frontend_subnet" {
  name          = "frontend-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.frontend_vpc.id
}

resource "google_compute_subnetwork" "backend_subnet" {
  name          = "backend-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.backend_vpc.id
}

# -------------------------
# VPC Peering
# -------------------------
resource "google_compute_network_peering" "frontend_to_backend" {
  name         = "frontend-to-backend"
  network      = google_compute_network.frontend_vpc.name
  peer_network = google_compute_network.backend_vpc.id
}

resource "google_compute_network_peering" "backend_to_frontend" {
  name         = "backend-to-frontend"
  network      = google_compute_network.backend_vpc.name
  peer_network = google_compute_network.frontend_vpc.id
}

# -------------------------
# Firewall - frontend
# -------------------------
resource "google_compute_firewall" "frontend_allow_icmp_http_api" {
  name    = "frontend-allow-icmp-http-api"
  network = google_compute_network.frontend_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "5000"]
  }

  source_ranges = ["10.0.2.0/24", "0.0.0.0/0"]
  target_tags   = ["frontend-vm"]
}

# -------------------------
# Firewall - backend
# -------------------------
resource "google_compute_firewall" "backend_allow_icmp_http_api" {
  name    = "backend-allow-icmp-http-api"
  network = google_compute_network.backend_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "5000"]
  }

  source_ranges = ["10.0.1.0/24", "0.0.0.0/0"]
  target_tags   = ["backend-vm"]
}

# -------------------------
# Backend VM
# -------------------------
resource "google_compute_instance" "backend_vm" {
  name         = "backend-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["backend-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.backend_subnet.id

    access_config {
    }
  }

  metadata_startup_script = file("${path.module}/startup-scripts/backend.sh")
}

# -------------------------
# Frontend VM
# -------------------------
resource "google_compute_instance" "frontend_vm" {
  name         = "frontend-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["frontend-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.frontend_subnet.id

    access_config {
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup-scripts/frontend.sh", {
    backend_ip = google_compute_instance.backend_vm.network_interface[0].network_ip
  })

  depends_on = [google_compute_instance.backend_vm]
}