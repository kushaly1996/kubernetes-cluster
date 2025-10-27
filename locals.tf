locals {
  flux-additional-sources = {
    flux-infrastructure = {
      repository_url = "https://github.com/kushaly1996/flux-infrastructure.git"
      branch         = "main"
    }
    flux-apps = {
      repository_url = "https://github.com/kushaly1996/flux-apps.git"
      branch         = "main"
    }
  }
}