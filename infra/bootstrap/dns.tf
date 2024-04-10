# VMS that provide supporting services (dns, monitoring, etc...)

# DNS container
resource "proxmox_lxc" "dns" {
  target_node = "pve-3"
  hostname = "dns"
  clone = "103"
  password = "proxmox"
  rootfs {
    storage = "test"
    size = "16G"
  }

  # SSH keys doesn't work on templates
#   ssh_public_keys = file(var.ssh_key)
  cores = 4
  memory = 4096
  nameserver = "8.8.8.8"

  network {
    name = "eth0"
    bridge = "vmbr0"
    ip = "172.16.100.30/24"
    gw = "172.16.100.1"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "172.16.100.30"
      user = "root"
      password = "proxmox"
    }
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${file(var.ssh_key)} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys"
    ]
  }
  start = true
  provisioner "local-exec" {
    command = "ssh-keygen -R 172.16.100.30 || true && pyinfra --ssh-user root 172.16.100.30 ./provisioning/dns.py"
  }
}