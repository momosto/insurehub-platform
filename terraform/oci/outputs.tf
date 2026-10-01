output "node_public_ip" {
  description = "Point Cloudflare DNS at this address (terraform/cloudflare reads it from this output)"
  value       = oci_core_instance.node.public_ip
}

output "backup_bucket" {
  value = oci_objectstorage_bucket.backups.name
}

output "object_storage_namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "ssh_tunnel_for_kubectl" {
  description = "The API server is not public; reach it through SSH"
  value       = "ssh -N -L 6443:127.0.0.1:6443 ${var.admin_user}@${oci_core_instance.node.public_ip}"
}
