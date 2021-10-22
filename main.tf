locals {
  cluster_type = "simple-regional-private"
  cluster_name_suffix = "00"
  compute_engine_service_account = "499880238003-compute@developer.gserviceaccount.com"
  ip_range_pods = "sandbox-2-dev-vpc-private-subnet-0-pods"
  ip_range_services = "sandbox-2-dev-vpc-private-subnet-0-svc"
  network = "sandbox-2-dev-vpc"
  project_id = "sandbox-roberto"
  region = "asia-southeast2"
  subnetwork = "sandbox-2-dev-vpc-private-subnet-0"

}

provider "google" {
  region  = local.region
  project = local.project_id
}

data "google_service_account" "compute-default-service-account" {
  account_id = "499880238003-compute@developer.gserviceaccount.com"
}


provider "google-beta" {
  region  = local.region
  project = local.project_id
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

data "google_compute_subnetwork" "subnetwork" {
  name    = local.subnetwork
  project = local.project_id
  region  = local.region
}

module "gke" {
  source                    = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                = local.project_id
  name                      = "${local.cluster_type}-cluster${local.cluster_name_suffix}"
  regional                  = true
  region                    = local.region
  network                   = local.network
  subnetwork                = local.subnetwork
  ip_range_pods             = local.ip_range_pods
  ip_range_services         = local.ip_range_services
  create_service_account    = false
  service_account           = data.google_service_account.compute-default-service-account.email
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
      service_account   = local.compute_engine_service_account
      preemptible       = true
      max_pods_per_node = 12
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
      display_name = "VPC"
    }
  ]
}