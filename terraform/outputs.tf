output "cluster_nodes" {
  description = "Nodes Information"
  value = {
    for k, node in module.pg_cluster : k => node.vm_ipv4_address
  }
}
output "ansible_inventory_raw" {
  description = "Raw YAML Inventory for Ansible"
  value       = local_file.ansible_inventory.content
  sensitive   = true
}