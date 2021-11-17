variable "project_id" {
  type = string
}

variable "region" {
  type = string
  default = "asia-southeast2"
}

variable "vpc_network_name" {
    type = string 
    default = null
}

variable "cluster_name" {
    type = string 
    default = null
}

variable "gke_subnet_ip_cidr" {
    type = string 
    default = "10.15.115.0/24"
}

variable "mgmt_subnet_ip_cidr" {
    type = string 
    default = "10.15.110.0/24"
}