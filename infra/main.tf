terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc1"
    }
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.13.5"
    }
  }
  required_version = ">= 0.14"
}

variable "proxmox_url" {
    type = string
    description = "Proxmox URL"
}

provider "proxmox" {
  pm_api_url = var.proxmox_url
  pm_debug   = true
  pm_parallel = 1
}

variable "tailscale_api_key" {
  type = string
  description = "Tailscale API key"
}

provider "tailscale" {
    api_key = var.tailscale_api_key
    tailnet = "-"
}