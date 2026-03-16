resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "vpc-${var.env}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  project                  = var.project_id
  name                     = "subnet-${var.env}-${var.region}"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # BigQuery/GCS への Private Access を有効化
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "router-${var.env}"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Composer Private Node などがアウトバウンドでインターネットへ出るための NAT
resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "nat-${var.env}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# デフォルト: 外部からのインバウンドを全て拒否
resource "google_compute_firewall" "deny_all_ingress" {
  project   = var.project_id
  name      = "deny-all-ingress-${var.env}"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# VPC 内部通信のみ許可
resource "google_compute_firewall" "allow_internal" {
  project   = var.project_id
  name      = "allow-internal-${var.env}"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}
