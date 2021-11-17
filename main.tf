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

module "service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 3.0"
  project_id    = var.project_id
  names         = ["gke-mgmt-sa"]
  project_roles = [
    "${var.project_id}=>roles/compute.admin",
    "${var.project_id}=>roles/container.admin",
    "${var.project_id}=>roles/iam.serviceAccountUser",
  ]
}

module "gke" {
  source                    = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                = var.project_id
  name                      = var.cluster_name
  regional                  = true
  region                    = var.region
  network                   = module.vpc.network_name
  subnetwork                = "gke-subnet-0"
  ip_range_pods             = "gke-subnet-0-pods"
  ip_range_services         = "gke-subnet-0-svc"
  create_service_account    = false
  service_account           = module.service_accounts.email
  enable_private_endpoint   = true
  enable_private_nodes      = true  
  master_ipv4_cidr_block    = "172.16.0.0/28"
  default_max_pods_per_node = 20
  remove_default_node_pool  = true

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
      service_account   = module.service_accounts.email
      preemptible       = true
      max_pods_per_node = 12
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = var.gke_subnet_ip_cidr
      display_name = "VPC"
    }
  ]
}