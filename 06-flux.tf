resource "time_sleep" "wait_for_aks" {
  depends_on      = [azurerm_kubernetes_cluster.aks, azurerm_kubernetes_cluster_node_pool.application_pool]
  create_duration = "100s" # wait 60 seconds (adjust as needed)
}

resource "kubectl_manifest" "namespace" {
  depends_on = [azurerm_role_assignment.aks_rbac_cluster_admin]
  yaml_body  = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: flux-system

YAML
}

resource "github_repository" "this" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "private"
  auto_init   = true # This is extremely important as flux_bootstrap_git will not work without a repository that has been initialised
}


resource "flux_bootstrap_git" "this" {
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    github_repository.this,
    kubectl_manifest.namespace
  ]
  namespace = var.flux_namespace
  path      = "clusters/my-cluster"
}

resource "github_repository_file" "system" {
  depends_on          = [github_repository.this, flux_bootstrap_git.this]
  repository          = github_repository.this.name
  branch              = "main"
  file                = "clusters/system.yaml "
  commit_message      = "Managed by Terraform"
  commit_author       = "kushal"
  commit_email        = "system for flux"
  overwrite_on_create = true
  autocreate_branch   = true
  content = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "system"
      namespace = "${var.flux_namespace}"
    }
    spec = {
      interval = "3m"
      path     = "clusters/extra/"
      prune    = true
      sourceRef = {
        kind = "GitRepository"
        name = "flux-system"
      }
      retryInterval = "1m"
      timeout       = "1m"
    }
  })
}

resource "github_repository_file" "flux_additional_sources" {
  depends_on     = [github_repository.this, flux_bootstrap_git.this]
  for_each       = local.flux-additional-sources
  repository     = github_repository.this.name
  branch         = "main"
  file           = "clusters/extra/extra-sources-${each.key}.yaml"
  commit_message = "Managed by Terraform"
  commit_author  = "kushal"
  commit_email   = "system for flux"
  content = yamlencode({
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = each.key
      namespace = "${var.flux_namespace}"
    }
    spec = {
      interval = "1m"
      url      = each.value.repository_url
      ref = {
        branch = each.value.branch
      }
      secretRef = {
        name = "flux-system"
      }
    }
  })
}

# resource "kubectl_manifest" "nginx_namespace" {
#   depends_on = [ azurerm_kubernetes_cluster.aks, azurerm_kubernetes_cluster_node_pool.application_pool,flux_bootstrap_git.this]
#   yaml_body = <<YAML
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: nginx-ingress

# YAML
# }

# resource "github_repository_file" "nginx_kustomizations" {
#   depends_on     = [github_repository.this, flux_bootstrap_git.this]
#   repository     = github_repository.this.name
#   branch         = "main"
#   file           = "clusters/extra/nginx-kustomization.yaml"
#   commit_message = "Managed by Terraform"
#   commit_author  = "kushal"
#   commit_email   = "system for flux"
#   content = yamlencode({
#     apiVersion = "kustomize.toolkit.fluxcd.io/v1"
#     kind       = "Kustomization"
#     metadata = {
#       name      = "infrastructure-ingress-nginx"
#       namespace = "${var.flux_namespace}"
#     }
#     spec = {
#       interval = "3m"
#       prune    = true
#       sourceRef = {
#         kind = "GitRepository"
#         name = "flux-infrastructure"
#       }
#       path = "base/nginx-ingress"
#       targetNamespace = "nginx-ingress"
#       retryInterval = "1m"
#       timeout       = "1m"
#     }
#   })
# }