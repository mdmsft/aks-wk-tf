resource "null_resource" "get_credentials" {
  provisioner "local-exec" {
    command = "az aks get-credentials -n ${var.cluster_name} -g ${var.resource_group_name} --context ${var.context_name} --overwrite-existing"
  }
}

resource "null_resource" "convert_kubeconfig" {
  provisioner "local-exec" {
    command = "kubelogin convert-kubeconfig -l azurecli"
  }
  depends_on = [
    null_resource.get_credentials
  ]
}

resource "kubernetes_secret_v1" "azure_secret" {
  depends_on = [
    null_resource.convert_kubeconfig
  ]

  metadata {
    name = "azure-secret"
  }

  data = {
    azurestorageaccountname = var.storage_account_name
    azurestorageaccountkey  = var.storage_access_key
  }
}

