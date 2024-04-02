terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc1"
    }
  }
}

variable "private_ssh_key" {
  description = "Path to ssh key to use for provisioning"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "name" {
  description = "Name of the vm"
  type        = string
}

variable "template" {
  description = "Name of the template to clone"
  type        = string
  default = "fedora-39-server"
}
variable "node" {
  description = "Node to deploy the vm on"
  type        = string
}

variable "ipconfig0" {
  description = "IP configuration for the VM"
  type        = string
  default = "ip=dhcp"
}

variable "networks" {
  description = "List of networks for the VM"
  type        = list(object({
    bridge = string
    mtu    = optional(number)
  }))
  default = [{
    bridge = "vmbr0"
    mtu    = 1500
  }]
}

variable "memory" {
  description = "Amount of memory to allocate to the VM"
  type        = number
  default     = 2048
}

variable "cores" {
  description = "Number of cores to allocate to the VM"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Size of the disk in GB"
  type        = number
  default     = 20
}
variable "tailscale_tailnet_key" {
  description = "Tailscale key"
  type        = string
}

variable "provisioning_script" {
  description = "Path to the provisioning script"
  type        = string
}

resource "proxmox_vm_qemu" "proxmox-vm" {
  agent       = 1
  onboot      = true
  target_node = var.node
  name        = var.name
  clone       = var.template
  #  full_clone = true
  #  boot = "order=scsi0"
  dynamic "network" {
    for_each = var.networks
    content {
      model  = "virtio"
      bridge = network.value.bridge
      mtu    = network.value.mtu
    }
  }
  memory                  = var.memory
  cores                   = var.cores
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "data"
  ciuser                  = "root"
  disks {
    ide {
      # Main disk
      ide0 {
        disk {
          size    = var.disk_size
          storage = "data"
        }
      }
    }
  }

  scsihw = "virtio-scsi-pci"
  provisioner "remote-exec" {
    inline = ["tailscale up --authkey ${var.tailscale_tailnet_key}"]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ssh_host
      timeout     = "20m"
      private_key = file(var.private_ssh_key)
    }
  }
  ipconfig0 = var.ipconfig0

  provisioner "local-exec" {
    command = "ssh-keygen -R ${self.ssh_host} || true && pyinfra --ssh-user root ${self.ssh_host} ${var.provisioning_script}"
  }
}
