provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = true
}

locals {
  # Definisi seluruh spesifikasi node (Hardcoded in code as Source of Truth)
  nodes = {
    "node01" = { id = 211, ip = "192.168.0.211", cores = 2, ram = 2048, disk = 30,  group = "database" }
    "node02" = { id = 212, ip = "192.168.0.212", cores = 2, ram = 2048, disk = 30,  group = "database" }
    "node03" = { id = 213, ip = "192.168.0.213", cores = 1, ram = 1024, disk = 20,  group = "witness" }
    "node04" = { id = 214, ip = "192.168.0.214", cores = 2, ram = 2048, disk = 50, group = "backup" }
  }
}

module "pg_cluster" {
  source   = "git::https://github.com/omidiyanto/proxmox-gitops-infrastructure-as-code.git//terraform/modules/proxmox_vm"
  for_each = local.nodes

  node_name   = "pve"
  vm_id       = each.value.id
  vm_name     = each.key
  clone_vm_id = 240

  cpu_cores = each.value.cores
  memory_mb = each.value.ram
  disk_size = each.value.disk

  ip_address = "${each.value.ip}/24"
  gateway    = "192.168.0.1"

  ssh_public_keys = [var.ssh_public_key]
}

# Auto-generate Ansible Inventory dalam format YAML standar
resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, v in local.nodes : k => {
          ansible_host = v.ip
          ansible_user = "ubuntu"
        }
      }
      children = {
        database = { hosts = { for k, v in local.nodes : k => {} if v.group == "database" } }
        witness  = { hosts = { for k, v in local.nodes : k => {} if v.group == "witness" } }
        backup   = { hosts = { for k, v in local.nodes : k => {} if v.group == "backup" } }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}