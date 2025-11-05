resource "azurerm_storage_account" "velero_sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "velero_container" {
  name                  = "velero-backups"
  storage_account_id    = azurerm_storage_account.velero_sa.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "velero_uami" {
  name                = "velero-uami"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "velero" {
  name                = "externaldns-fic"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.velero_uami.id
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:velero:velero"
  audience            = ["api://AzureADTokenExchange"]
}
resource "azurerm_role_assignment" "velero_storage_account_role" {
  scope                = azurerm_storage_account.velero_sa.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.velero_uami.principal_id
}

resource "azurerm_role_assignment" "velero_storage_account_blob_role" {
  scope                = azurerm_storage_account.velero_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.velero_uami.principal_id
}

data "azurerm_resource_group" "aks_nodes_rg" {
  depends_on = [ azurerm_kubernetes_cluster.aks ]
  name = "MC_rg-aks-kubenet-demo_aks-kubenet-cluster_eastus"
}

resource "azurerm_role_assignment" "velero_snapshot_role" {
  scope                = data.azurerm_resource_group.aks_nodes_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.velero_uami.principal_id
}