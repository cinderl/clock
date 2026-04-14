terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Install Traefik Ingress Controller
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = "traefik"
  create_namespace = true

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "ports.web.nodePort"
    value = "30080"
  }

  set {
    name  = "ports.websecure.nodePort"
    value = "30443"
  }

  set {
    name  = "deployment.kind"
    value = "DaemonSet"
  }

  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/control-plane"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "nodeSelector.ingress-ready"
    value = "true"
    type  = "string"
  }
}

# Apply Traefik CRDs
resource "null_resource" "traefik_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.3/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml"
  }

  depends_on = [helm_release.traefik]
}

# Deploy the Clock application
resource "helm_release" "clock" {
  name             = var.release_name
  chart            = "../helm/clock-local"
  namespace        = var.namespace
  create_namespace = false

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.path"
    value = var.ingress_path
  }

  # Add other values as needed

  depends_on = [null_resource.traefik_crds]
}