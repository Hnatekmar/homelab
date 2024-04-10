terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc1"
    }
  }
  required_version = ">= 0.14"
}

variable "proxmox_url" {
  type = string
  description = "Proxmox URL"
  default = "https://pve-1:8006/api2/json"
}

provider "proxmox" {
  pm_api_url = var.proxmox_url
  pm_debug   = true
  pm_log_enable = true
  pm_log_levels = {
    _default = "debug"
  }
  pm_parallel = 1
}

variable "ssh_key" {
  type = string
  description = "SSH public key"
  default = "~/.ssh/id_ed25519"
}

provider "dns" {
  update {
    server        = "172.16.100.30"
    key_name      = "private.hnatekmar.xyz."
    key_algorithm = "hmac-sha256"
    key_secret    = file("/tmp/tsig-key")
  }
}
