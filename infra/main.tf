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

resource "proxmox_vm_qemu" "kube-master" {
  for_each = toset(["pve-0"])
  agent = 1
  target_node = each.value
  name = "k8s-master"
  desc = "testing terraform"
  clone = "fedora-server-base"
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  network {
    model = "virtio"
    bridge = "vmbr2"
    mtu = 9000
  }
  memory = 2096
  cores = 4
  os_type = "cloud-init"
  cloudinit_cdrom_storage = "data"
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
          size               = 8
          storage            = "data"
        }
      }
    }
  }
  scsihw = "virtio-scsi-single"

  provisioner "local-exec" {
    # TODO: this is a hack, we need to wait for the master to be up and running before we can provision the worker. Need to actively check for ssh port
    command = "sleep 25 && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_master.py"
  }
}

resource "proxmox_vm_qemu" "kube-worker" {
  for_each = toset(["pve-0", "pve-1"])
#  for_each =
  agent = 1
  target_node = each.value
  name = "k8s-worker-${each.key}"
  desc = "testing terraform"
  clone = "fedora-server-base"
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  network {
    model = "virtio"
    bridge = "vmbr2"
    mtu = 9000
  }
  memory = 2096
  cores = 4
  os_type = "cloud-init"
  cloudinit_cdrom_storage = "data"
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
          size               = 64
          storage            = "data"
        }
      }
    }
  }
  scsihw = "virtio-scsi-single"
  depends_on = [proxmox_vm_qemu.kube-master]

  provisioner "local-exec" {
    # TODO: this is a hack, we need to wait for the master to be up and running before we can provision the worker. Need to actively check for ssh port
    command = "sleep 25 && export K3S_TOKEN=$(ssh root@${proxmox_vm_qemu.kube-master["pve-0"].ssh_host} cat /var/lib/rancher/k3s/server/token) && export K3S_URL=https://${proxmox_vm_qemu.kube-master["pve-0"].ssh_host}:6443 && pyinfra --ssh-user root ${self.ssh_host} ./provisioning/k3s_worker.py"
  }
}
