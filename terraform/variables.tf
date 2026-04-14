variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "my-clock-release"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy to"
  type        = string
  default     = "default"
}

variable "image_tag" {
  description = "Docker image tag to use"
  type        = string
  default     = "ci"
}

variable "ingress_path" {
  description = "Ingress path for the application"
  type        = string
  default     = "/clock"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}