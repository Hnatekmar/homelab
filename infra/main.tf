terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://172.16.100.10:8006/api2/json"
  pm_debug = true
}

resource "proxmox_vm_qemu" "nginx" {
  for_each = toset(["pve-0", "pve-1"])
  agent = 1
  target_node = each.value
  name = "nginx"
  desc = "testing terraform"
  clone = "fedora-server-base"
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  memory = 4096
  cores = 4
  os_type = "cloud-init"
  cloudinit_cdrom_storage = "local-lvm"
  ciuser = "root"
  disks {
    scsi {
      scsi0 {
        disk {
          backup             = true
          discard            = true
          emulatessd         = true
          iothread           = true
          replicate          = true
          size               = 16
          storage            = "local-lvm"
        }
      }
    }
  }
  scsihw = "virtio-scsi-single"

  provisioner "local-exec" {
    command = "sleep 60 && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/nginx.py"
  }
}