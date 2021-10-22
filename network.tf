module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 3.0"

    project_id   = local.project_id
    network_name = "sandbox-2-gke-ref-vpc"
    routing_mode = "GLOBAL"
    delete_default_internet_gateway_routes = true

    subnets = [
        {
            subnet_name           = "gke-subnet-01"
            subnet_ip             = "10.113.20.0/24"
            subnet_region         = local.region
            subnet_private_access = "true"
            subnet_flow_logs      = "false"
            description           = "This subnet has a description"
        },
    ]

    secondary_ranges = {
        gke-subnet-01 = [
            {
                range_name    = "gke-subnet-01-pods"
                ip_cidr_range = "192.168.64.0/24"
            },
            {
                range_name    = "gke-subnet-01-services"
                ip_cidr_range = "192.168.65.0/24"
            },
        ]

        subnet-02 = []
    }

    routes = [
        {
            name                   = "egress-internet"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet"
            next_hop_internet      = "true"
        },
        {
            name                   = "app-proxy"
            description            = "route through proxy to reach app"
            destination_range      = "10.50.10.0/24"
            tags                   = "app-proxy"
            next_hop_instance      = "app-proxy-instance"
            next_hop_instance_zone = "us-west1-a"
        },
    ]
}
