# install kubectl, google-cloud-sdk
# service account need kubernetes admin to set rbac
module "instance_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  project_id         = local.project_id
  subnetwork         = local.subnetwork
  machine_type       = "e2-small"
  tags               = ["ssh", "public"]
  #["egress-all", "iap-ssh or ssh"]
  service_account    = {
      email = data.google_service_account.compute-default-service-account.email
      scopes = ["cloud-platform"]
      }
  subnetwork_project = local.project_id
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  project_id        = local.project_id
  region            = local.region
  target_size       = 1
  hostname          = "mig-bastion-host"
  instance_template = module.instance_template.self_link
}