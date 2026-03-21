output "cluster_nodes" {
  description = "Nodes Information"
  value = {
    for k, node in module.pg_cluster : k => node.vm_ipv4_address
  }
}