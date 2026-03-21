terraform {
  cloud {
    organization = "__HCP_ORG__"
    workspaces {
      name = "__HCP_WORKSPACE__"
    }
  }
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}