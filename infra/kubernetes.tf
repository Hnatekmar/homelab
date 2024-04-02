variable "proxmox_nodes" {
  description = "List of proxmox nodes to deploy VMs on"
  type        = list(string)
  default     = ["pve-0", "pve-1", "pve-3"]
}

variable "k3s_master_memory" {
  description = "Memory for the master node"
  default     = 2048
  type        = number
}

variable "k3s_worker_memory" {
  description = "Memory for the master node"
  default     = 4096
  type        = number
}

variable "private_ssh_key" {
  description = "SSH key to use for provisioning"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

resource "tailscale_tailnet_key" "kubernetes" {
  reusable = true
}

resource "proxmox_vm_qemu" "kube-master" {
  for_each    = toset([var.proxmox_nodes[0]])
  agent       = 1
  onboot      = true
  target_node = each.value
  name        = "k3s-master"
  desc        = "k3s master"
  clone       = "fedora-39-server"
  #  full_clone = true
  #  boot = "order=scsi0"
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  network {
    model  = "virtio"
    bridge = "vmbr2"
    mtu    = 9000
  }
  memory                  = var.k3s_master_memory
  cores                   = 4
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "nas"
  ciuser                  = "root"
  disks {
    ide {
      # Main disk
      ide0 {
        disk {
          size    = "20"
          storage = "data"
        }
      }
    }
  }

  scsihw = "virtio-scsi-pci"
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=dhcp"
  provisioner "remote-exec" {
    inline = ["tailscale up --authkey ${tailscale_tailnet_key.kubernetes.key}"]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ssh_host
      timeout     = "20m"
      private_key = file(var.private_ssh_key)
    }
  }

  provisioner "local-exec" {
    command = "ssh-keygen -R ${self.ssh_host} && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_master.py"
  }
}


resource "proxmox_vm_qemu" "kube-worker" {
  for_each    = toset(var.proxmox_nodes)
  agent       = 1
  onboot      = true
  target_node = each.value
  name        = "k3s-worker-${each.value}"
  desc        = "k3s worker"
  clone       = "fedora-39-server"
  depends_on = [
    proxmox_vm_qemu.kube-master
  ]
  #  full_clone = true
  #  boot = "order=scsi0"
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  network {
    model  = "virtio"
    bridge = "vmbr2"
    mtu    = 9000
  }
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=dhcp"
  memory                  = var.k3s_worker_memory
  cores                   = 4
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "nas"
  ciuser                  = "root"
  disks {
    ide {
      ide0 {
        disk {
          size    = "100"
          storage = "data"
        }
      }
    }
  }
  vmid = 900 + index(var.proxmox_nodes, each.value)
  scsihw = "virtio-scsi-pci"

  provisioner "remote-exec" {
    inline = ["tailscale up --authkey ${tailscale_tailnet_key.kubernetes.key}"]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ssh_host
      timeout     = "20m"
      private_key = file(var.private_ssh_key)
    }
  }

  provisioner "local-exec" {
    command = "ssh-keygen -R ${self.ssh_host} && export K3S_TOKEN=$(ssh -o 'StrictHostKeyChecking no' -o UserKnownHostsFile=/dev/null root@k3s-master cat /var/lib/rancher/k3s/server/node-token) && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_worker.py"
  }
}
