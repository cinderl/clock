output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.clock.status
}

output "helm_release_version" {
  description = "Version of the deployed Helm release"
  value       = helm_release.clock.version
}

output "release_name" {
  description = "Name of the deployed release"
  value       = var.release_name
}