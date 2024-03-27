variable "proxmox_nodes" {
  description = "List of proxmox nodes to deploy VMs on"
  type        = list(string)
  default     = ["pve-0", "pve-1"]
}

variable "k3s_master_memory" {
  description = "Memory for the master node"
  default     = 4096
  type        = number
}

variable "private_ssh_key" {
  description = "SSH key to use for provisioning"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

resource "proxmox_vm_qemu" "kube-master" {
  for_each    = toset([var.proxmox_nodes[0]])
  agent       = 1
  onboot      = true
  target_node = each.value
  name        = "k8s-master"
  desc        = "testing terraform"
  clone       = "fedora-server-base"
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
  cores                   = 2
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "data"
  ciuser                  = "root"
  disks {
    scsi {
      scsi0 {
        disk {
          backup     = true
          discard    = true
          emulatessd = true
          iothread   = true
          replicate  = true
          size       = 8
          storage    = "data"
        }
      }
    }
  }
  scsihw = "virtio-scsi-single"

  provisioner "remote-exec" {
    inline = ["echo 'SSH ready'"]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ssh_host
      timeout     = "20m"
      private_key = file(var.private_ssh_key)
    }
  }

  provisioner "local-exec" {
    # TODO: this is a hack, we need to wait for the master to be up and running before we can provision the worker. Need to actively check for ssh port
    command = "pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_master.py"
  }
}

resource "proxmox_vm_qemu" "kube-worker" {
  for_each    = toset(var.proxmox_nodes)
  agent       = 1
  onboot      = true
  target_node = each.value
  name        = "k8s-worker-${each.key}"
  desc        = "testing terraform"
  clone       = "fedora-server-base"
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  network {
    model  = "virtio"
    bridge = "vmbr2"
    mtu    = 9000
  }
  memory                  = 2096
  cores                   = 4
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "data"
  ciuser                  = "root"
  disks {
    scsi {
      scsi0 {
        disk {
          backup     = true
          discard    = true
          emulatessd = true
          iothread   = true
          replicate  = true
          size       = 64
          storage    = "data"
        }
      }
    }
  }
  scsihw     = "virtio-scsi-single"
  depends_on = [proxmox_vm_qemu.kube-master]

  provisioner "remote-exec" {
    inline = ["echo 'SSH ready'"]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ssh_host
      timeout     = "20m"
      private_key = file(var.private_ssh_key)
    }
  }

  provisioner "local-exec" {
    command = "export K3S_TOKEN=$(ssh root@${proxmox_vm_qemu.kube-master[var.proxmox_nodes[0]].ssh_host} cat /var/lib/rancher/k3s/server/token) && export K3S_URL=https://${proxmox_vm_qemu.kube-master[var.proxmox_nodes[0]].ssh_host}:6443 && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_worker.py"
  }
}
