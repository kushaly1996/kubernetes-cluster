resource "azurerm_user_assigned_identity" "externaldns" {
  name                = "externaldns-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_federated_identity_credential" "externaldns" {
  name                = "externaldns-fic"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.externaldns.id
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:external-dns:external-dns"
  audience            = ["api://AzureADTokenExchange"]
}
resource "azurerm_role_assignment" "externaldns_identity_reader" {
  principal_id         = azurerm_user_assigned_identity.externaldns.principal_id
  role_definition_name = "Reader"
  scope                = azurerm_resource_group.rg.id
}

resource "azurerm_role_assignment" "externaldns_dns_contributor" {
  principal_id         = azurerm_user_assigned_identity.externaldns.principal_id
  role_definition_name = "Private DNS Zone Contributor"
  scope                = azurerm_private_dns_zone.private_zone.id
}