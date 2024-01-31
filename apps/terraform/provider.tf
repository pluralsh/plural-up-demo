terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "plrlupdem-tf-state"
    key = "up-demo/apps/terraform.tfstate"
    region = "us-east-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    plural = {
      source = "pluralsh/plural"
      version = ">= 0.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_eks_cluster" "cluster" {
  name = "up-demo"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "up-demo"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "kubernetes_secret" "console-auth" {
  metadata {
    name = "console-auth-token"
    namespace = "plrl-console"
  }
}

provider "plural" {
  console_url = "https://console.up-demo.onplural.sh"
  access_token = data.kubernetes_secret.console-auth.data.access-token
}