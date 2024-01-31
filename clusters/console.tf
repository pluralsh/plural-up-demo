// leave this resource static, if you want to modify console values, do it in the generated helm values directly instead.
resource "null_resource" "console" {
  provisioner "local-exec" {
    command = "plural cd control-plane-values --name up-demo --dsn \"${module.mgmt.db_url}\" --domain up-demo.onplural.sh --file console.yaml"
    working_dir = "${path.module}/../helm-values"
  }
}

data "local_sensitive_file" "certmanager" {
  filename = "${path.module}/../helm-values/certmanager.yaml"
}

data "local_sensitive_file" "flux" {
  filename = "${path.module}/../helm-values/flux.yaml"
}

data "local_sensitive_file" "runtime" {
  filename = "${path.module}/../helm-values/runtime.yaml"
}

data "local_sensitive_file" "console" {
  filename = "${path.module}/../helm-values/console.yaml"
  depends_on = [ null_resource.console ]
}

resource "helm_release" "certmanager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "v1.13.3"
  create_namespace = true
  timeout          = 300
  wait             = true
  values           = [
    data.local_sensitive_file.certmanager.content
  ]

  depends_on = [ module.mgmt.cluster, module.mgmt.ready ]
}

resource "helm_release" "flux" {
  name             = "flux"
  namespace        = "flux"
  chart            = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  version          = "2.12.2"
  create_namespace = true
  timeout          = 300
  wait             = false
  values           = [
    data.local_sensitive_file.flux.content
  ]

  depends_on = [ module.mgmt.cluster ]
}

resource "helm_release" "runtime" {
  name             = "runtime"
  namespace        = "plural-runtime"
  chart            = "runtime"
  repository       = "https://pluralsh.github.io/bootstrap"
  version          = "0.1.17"
  create_namespace = true
  timeout          = 300
  wait             = false
  values           = [
    data.local_sensitive_file.runtime.content
  ]

  depends_on = [ module.mgmt.cluster, helm_release.certmanager, helm_release.flux ]
}

resource "helm_release" "console" {
  name             = "console"
  namespace        = "plrl-console"
  chart            = "console"
  repository       = "https://pluralsh.github.io/console"
  version          = "0.1.26"
  create_namespace = true
  timeout          = 600
  wait             = true
  values           = [
    data.local_sensitive_file.console.content
  ]

  depends_on = [ module.mgmt.cluster, helm_release.runtime, module.mgmt.db_url ]
}