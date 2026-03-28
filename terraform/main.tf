provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = true
}

locals {
  haproxy_vip = "192.168.0.250"
  nodes = {
    "patroni01" = { pve_node = "pve", id = 211, ip = "192.168.0.211", cores = 2, ram = 2048, disk = 30, group = "database" }
    "patroni02" = { pve_node = "pve", id = 212, ip = "192.168.0.212", cores = 2, ram = 2048, disk = 30, group = "database" }
    "witness"   = { pve_node = "pve", id = 213, ip = "192.168.0.213", cores = 1, ram = 512,  disk = 20, group = "witness" }
    "lb01"      = { pve_node = "pve", id = 214, ip = "192.168.0.214", cores = 1, ram = 1024, disk = 20, group = "loadbalancer" }
    "lb02"      = { pve_node = "pve", id = 215, ip = "192.168.0.215", cores = 1, ram = 1024, disk = 20, group = "loadbalancer" }
    "rustfs"    = { pve_node = "pve", id = 216, ip = "192.168.0.216", cores = 2, ram = 2048, disk = 50, group = "backup" }
  }
}

module "pg_cluster" {
  source   = "git::https://github.com/omidiyanto/proxmox-gitops-infrastructure-as-code.git//terraform/modules/proxmox_vm"
  for_each = local.nodes

  node_name   = each.value.pve_node
  vm_id       = each.value.id
  vm_name     = each.key
  clone_vm_id = 240

  cpu_cores = each.value.cores
  memory_mb = each.value.ram
  disk_size = each.value.disk

  ip_address  = "${each.value.ip}/24"
  gateway     = "192.168.0.1"
  dns_servers = ["8.8.8.8"]

  ssh_public_keys = [var.ssh_public_key]
}

# Auto-generate Ansible Inventory
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
        loadbalancer = {
          hosts = { for k, v in local.nodes : k => {} if v.group == "loadbalancer" }
          vars = {
            vip_address = local.haproxy_vip
          }
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}