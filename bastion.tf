# install kubectl, google-cloud-sdk
# service account need kubernetes admin to set rbac
module "bastion_instance_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  project_id         = var.project_id
  subnetwork         = "mgmt-subnet-0"
  machine_type       = "e2-small"
  tags               = ["egress-inet", "iap-ssh"]
  service_account    = {
      email = module.gke_service_accounts.email
      scopes = ["cloud-platform"]
  }
  subnetwork_project = var.project_id

  startup_script = <<-EOT
    #!/bin/bash
    export HOME=/root
    sudo yum install -q -y kubectl google-cloud-sdk && \
    gcloud container clusters --project=${var.project_id} get-credentials --region=${var.region} ${var.cluster_name} && \
    kubectl create namespace argocd && \
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  EOT
  depends_on = [ module.vpc, module.gke ]
}

module "bastion_mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  project_id        = var.project_id
  region            = var.region
  target_size       = 1
  hostname          = "mig-bastion-host"
  instance_template = module.bastion_instance_template.self_link
}