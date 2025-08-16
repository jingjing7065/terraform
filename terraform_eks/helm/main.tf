terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.29.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../eks/terraform.tfstate"
  }
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}


provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "58.3.0" # 版本可以根据需要调整
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false
  timeout          = 600
  depends_on       = [kubernetes_namespace.monitoring]

  values = [
    yamlencode({
      alertmanager = {
        enabled = false
      }

      grafana = {
        adminUser     = "admin"
        adminPassword = "admin123"

        service = {
          type = "LoadBalancer"
          port = 80
        }

        persistence = {
          enabled = false
        }

        # datasources = {
        #   "datasources.yaml" = {
        #     apiVersion = 1
        #     datasources = [
        #       {
        #         name      = "Prometheus"
        #         type      = "prometheus"
        #         access    = "proxy"
        #         url       = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local"
        #         isDefault = true
        #       }
        #     ]
        #   }
        # }
      }

      prometheus = {
        prometheusSpec = {
          retention   = "7d"
          storageSpec = {} # 不启用持久化
        }
      }
    })
  ]
}
