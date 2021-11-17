module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 3.0"

    project_id   = var.project_id
    network_name = var.vpc_network_name
    routing_mode = "GLOBAL"
    delete_default_internet_gateway_routes = true

    subnets = [
        {
            subnet_name           = "gke-subnet-0"
            subnet_ip             = var.gke_subnet_ip_cidr
            subnet_region         = var.region
            subnet_private_access = "true"
            subnet_flow_logs      = "false"
            description           = "Subnet for GKE cluster"
        },
        {
            subnet_name           = "mgmt-subnet-0"
            subnet_ip             = var.mgmt_subnet_ip_cidr
            subnet_region         = var.region
            subnet_private_access = "true"
            subnet_flow_logs      = "false"
            description           = "Subnet for administration"
        },
    ]

    secondary_ranges = {
        gke-subnet-0 = [
            {
                range_name    = "gke-subnet-0-pods"
                ip_cidr_range = "192.168.64.0/24"
            },
            {
                range_name    = "gke-subnet-0-svc"
                ip_cidr_range = "192.168.65.0/24"
            },
        ]

        mgmnt-subnet-0 = []
    }

    routes = [
        {
            name                   = "egress-internet"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet,gke-${var.cluster_name}"
            next_hop_internet      = "true"
        }
    ]
}

# Use NAT for egress communication
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "nat-router"
  network = var.vpc_network_name
  region  = var.region
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 2.0.0"
  project_id                         = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  name                               = "nat-config"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "allow_iap" {
  project = var.project_id
  name    = "iap-ssh"
  network = var.vpc_network_name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}