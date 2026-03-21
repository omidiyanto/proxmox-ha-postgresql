output "cluster_nodes" {
  description = "Informasi Nodes Cluster yang berhasil dibuat"
  value = {
    for k, node in module.pg_cluster : k => node.vm_ipv4_address
  }
}