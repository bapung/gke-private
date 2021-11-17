# install kubectl, google-cloud-sdk
# service account need kubernetes admin to set rbac
module "instance_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  project_id         = var.project_id
  subnetwork         = "mgmt-subnet-0"
  machine_type       = "e2-small"
  tags               = ["egress-inet", "iap-ssh"]
  service_account    = {
      email = module.service_accounts.email
      scopes = ["cloud-platform"]
      }
  subnetwork_project = var.project_id
  startup_script = <<-EOT
    #!/bin/bash

    sudo yum install -y kubectl google-cloud-sdk
    gcloud container clusters get-credentials ${var.cluster_name}
  EOT
  depends_on = [ module.vpc ]
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  project_id        = var.project_id
  region            = var.region
  target_size       = 1
  hostname          = "mig-bastion-host"
  instance_template = module.instance_template.self_link
}

