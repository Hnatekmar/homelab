terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc1"
    }
  }
  required_version = ">= 0.14"
}

provider "proxmox" {
  pm_api_url = "https://172.16.100.10:8006/api2/json"
  pm_debug   = true
}
