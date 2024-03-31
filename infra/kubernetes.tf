variable "proxmox_nodes" {
  description = "List of proxmox nodes to deploy VMs on"
  type        = list(string)
  default     = ["pve-0", "pve-1", "pve-3"]
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
  cores                   = 2
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "nas"
  ciuser                  = "root"
  disks {
    ide {
      ide0 {
        disk {
          size    = "20"
          storage = "nas"
        }
      }
    }
  }
  scsihw = "virtio-scsi-pci"
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
    command = "ssh-keygen -R ${self.ssh_host} && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_master.py"
  }
}

