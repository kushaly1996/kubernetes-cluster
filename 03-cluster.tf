resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.cluster_name
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = var.cluster_name
  kubernetes_version      = var.kubernetes_version

  default_node_pool {
    name           = "systempool"
    vm_size        = var.node_vm_size
    node_count     = var.node_count
    vnet_subnet_id = azurerm_subnet.aks.id # Attaching the nodes to the subnet
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.externaldns.id]
  }
  oidc_issuer_enabled = true
  workload_identity_enabled = true

  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings,
    ]
  }
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = "6f818e3d-ede0-4045-a285-0a6c77b4cabb"
  }

  # --- Kubenet Configuration ---
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    # CIDR for the Kubernetes Services (ClusterIPs)
    service_cidr = var.service_cidr
    # CIDR for the Pods - must be separate from the VNet/Subnet CIDRs
    pod_cidr = var.pod_cidr
    # IP for the Kubernetes DNS service (usually x.x.x.10 of the service_cidr)
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "application_pool" {
  # Required properties
  name                  = "apppool"                         # A name for the node pool (e.g., apppool, linuxapp)
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id # Reference the existing AKS cluster ID
  vm_size               = "standard_a2_v2"                  # Choose an appropriate VM size
  node_count            = 1                                 # Initial number of nodes
  mode                  = "User"                            # Designate it as a User (Application) node pool

  # Optional but recommended settings for an application-specific pool

  # 1. Autoscaling configuration (optional)
  auto_scaling_enabled = true
  min_count            = 1
  max_count            = 5

  # 2. Taint for workload isolation (optional but common for app pools)
  # This makes sure only pods that tolerate this taint are scheduled here.
  node_taints = ["app=critical:NoSchedule"]

  lifecycle {
    ignore_changes = [
      upgrade_settings,
      vnet_subnet_id,
    ]
  }
  # 3. Label for node selector/affinity (optional)
  node_labels = {
    "kubelet.kubernetes.io/role" = "application"
    "environment"                = "production"

  }

  # 4. Networking (if using a specific VNet/Subnet)
  # Note: The subnet must be the same one used by the other node pools in the cluster.
  # vnet_subnet_id      = "/subscriptions/..." 
}

# Grant "Azure Kubernetes Service RBAC Cluster Admin" to a Service Principal on the AKS cluster
resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = "e9620a65-12b3-43f8-b4e9-3bff15479ade" # SP_ID

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "azurerm_private_dns_zone" "private_zone" {
  name                = "internal.example.com"
  resource_group_name = azurerm_resource_group.rg.name
}

