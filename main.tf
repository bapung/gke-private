provider "google" {
  region  = var.region
  project = var.project_id
}


provider "google-beta" {
  region  = var.region
  project = var.project_id
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke_service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  project_id    = var.project_id
  names         = ["gke-mgmt-sa"]
  project_roles = [
    "${var.project_id}=>roles/compute.admin",
    "${var.project_id}=>roles/container.admin",
    "${var.project_id}=>roles/iam.serviceAccountUser",
  ]
}

module "gke" {
  source                      = "terraform-google-modules/kubernetes-engine/google"
  version                     = "~> 17.0"
  project_id                  = var.project_id
  name                        = var.cluster_name
  regional                    = true
  region                      = var.region
  network                     = module.vpc.network_name
  subnetwork                  = "gke-subnet-0"
  ip_range_pods               = "gke-subnet-0-pods"
  ip_range_services           = "gke-subnet-0-svc"
  add_cluster_firewall_rules  = true
  create_service_account      = false
  service_account             = module.gke_service_accounts.email
  remove_default_node_pool    = true

  node_pools = [
    {
      name              = "pool-01"
      min_count         = 1
      max_count         = 3
      local_ssd_count   = 0
      disk_size_gb      = 50
      disk_type         = "pd-standard"
      image_type        = "COS"
      auto_repair       = true
      auto_upgrade      = true
      service_account   = module.gke_service_accounts.email
      preemptible       = true
      max_pods_per_node = 12
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = var.gke_subnet_ip_cidr
      display_name = "gke-subnet"
    },
    {
      cidr_block   = var.mgmt_subnet_ip_cidr
      display_name = "management-subnet"
    },
    {
      cidr_block   = var.lb_subnet_ip_cidr
      display_name = "load-balancer-subnet"
    },
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "vpn-network"
    }
  ]
}