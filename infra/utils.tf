# Utility vms

variable "proxy-node" {
  default = "pve-1"
  type    = string
}

resource "proxmox_vm_qemu" "public-proxy" {
  for_each    = toset([var.proxy-node])
  agent       = 1
  target_node = each.value
  name        = "public-proxy"
  desc        = "testing terraform"
  clone       = "fedora-server-base"
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  memory                  = 1024
  cores                   = 1
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
    command = "pyinfra --ssh-user root ${self.ssh_host} ./provisioning/public_proxy.py"
  }
}
