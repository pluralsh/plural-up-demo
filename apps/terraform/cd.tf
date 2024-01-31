locals {
  context = yamldecode(data.local_sensitive_file.context.content)
}

data "local_sensitive_file" "context" {
  filename = "${path.module}/../../context.yaml"
}

data "plural_cluster" "mgmt" {
    handle = "mgmt"
}

// create the kubernetes namespace manually here so it can be used elsewhere w/in terraform w/o race conditions
resource "kubernetes_namespace" "infra" {
    metadata {
      name = "infra"
    }
}

resource "plural_git_repository" "infra" {
    url         = local.context.spec.configuration.console.repo_url
    private_key = local.context.spec.configuration.console.private_key
    decrypt     = true
}

resource "plural_service_deployment" "helm-repositories" {
    name = "helm-repositories"
    namespace = kubernetes_namespace.infra.metadata[0].name
    repository = {
        id = plural_git_repository.infra.id
        ref = "main"
        folder = "apps/repositories"
    }
    cluster = {
        id = data.plural_cluster.mgmt.id
    }
    protect = true

    depends_on = [ kubernetes_namespace.infra ]
}

resource "plural_service_deployment" "apps" {
    name = "apps"
    namespace = kubernetes_namespace.infra.metadata[0].name
    repository = {
        id = plural_git_repository.infra.id
        ref = "main"
        folder = "apps/services"
    }
    cluster = {
        id = data.plural_cluster.mgmt.id
    }
    configuration = {
        repoUrl  = local.context.spec.configuration.console.repo_url 
    }
    protect = true

    depends_on = [ kubernetes_namespace.infra ]
}