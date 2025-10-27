variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-aks-kubenet-demo"
}


variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
  default     = "aks-kubenet-cluster"
}

variable "vnet_cidr" {
  description = "The address space for the VNet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "The subnet for the AKS worker nodes (must be a subset of vnet_cidr)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "kubernetes_version" {
  description = "The Kubernetes version."
  type        = string
  default     = "1.32.7" # Use a valid, supported version
}

variable "node_vm_size" {
  description = "The size of the Virtual Machine for the nodes."
  type        = string
  default     = "standard_a2_v2"
}

variable "node_count" {
  description = "The desired number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "service_cidr" {
  description = "The Kubernetes Service CIDR (must NOT overlap with VNet/Subnet/Pod CIDRs)."
  type        = string
  default     = "172.16.0.0/24"
}

variable "pod_cidr" {
  description = "The Pod CIDR (must NOT overlap with VNet/Subnet/Service CIDRs)."
  type        = string
  default     = "192.168.0.0/16"
}

variable "dns_service_ip" {
  description = "The IP address for the Kubernetes DNS service (must be in service_cidr, usually x.x.x.10)."
  type        = string
  default     = "172.16.0.10"
}

variable "github_repository" {
  description = "GitHub repository"
  type        = string
  default     = "flux-repo"
}

variable "flux_namespace" {
  description = "The namespace to install Flux into"
  type        = string
  default     = "flux-system"
}

variable "github_token" {
  description = "GitHub Personal Access Token with repo and admin:repo_hook scopes"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization or user name"
  type        = string
  default     = "kushaly1996"
}

variable "flux_additional_sources" {
  description = "Additional Git repositories to be added as sources in Flux"
  type = map(object({
    repository_url = string
    branch         = string
  }))
  default = {}
}