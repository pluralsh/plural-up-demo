module "mgmt" {
    source        = "../bootstrap/terraform/clouds/aws"
    cluster_name  = "up-demo"
}