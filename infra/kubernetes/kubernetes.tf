variable "master_node" {
  description = "List of proxmox nodes to deploy VMs on"
  type        = string
  default     = "pve-0"
}

variable "worker_nodes" {
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


module "kube-master" {
 providers = {
   proxmox = proxmox
 }
 source = "./vm"
 name = "k3s-master.private.hnatekmar.xyz"
 node = var.master_node
 memory = var.k3s_master_memory
 private_ssh_key = var.ssh_key
 provisioning_script = "./provisioning/k3s_master.yaml"
 ipconfig0 = "ip=dhcp"
 cores = 2
 networks = [
   {
     model = "virtio"
     bridge = "vmbr0"
   },
   {
     model = "virtio"
     bridge = "vmbr2"
     mtu = 9000
   }
 ]
}

resource "dns_a_record_set" "kube-master-dns" {
  addresses = [module.kube-master.ip]
  zone      = "private.hnatekmar.xyz."
  name = "k3s-master"
  depends_on = [module.kube-master]
}

module "kube-worker" {
  depends_on = [dns_a_record_set.kube-master-dns]
  providers = {
    proxmox = proxmox
  }
  for_each = toset(var.worker_nodes)
  source = "./vm"
  name = "k3s-worker-${each.value}.private.hnatekmar.xyz"
  node = each.value
  private_ssh_key = var.ssh_key
  provisioning_script = "./provisioning/k3s_worker.yaml"
  ipconfig0 = "ip=dhcp"
  memory = var.k3s_worker_memory
  cores = 4
  networks = [
    {
      model = "virtio"
      bridge = "vmbr0"
    },
    {
      model = "virtio"
      bridge = "vmbr2"
      mtu = 9000
    }
  ]
}

resource "dns_a_record_set" "kube-worker-dns" {
  depends_on = [module.kube-worker]
  for_each = toset(var.worker_nodes)
  addresses = [module.kube-worker[each.value].ip]
  zone      = "private.hnatekmar.xyz."
  name = "k3s-worker-${each.value}"
}

#
#module "kube-worker" {
#  providers = {
#    proxmox = proxmox
#  }
#  source = "./vm"
#  for_each = toset(var.worker_nodes)
#  name        = "k3s-worker-${each.value}"
#  node                  = each.value
#  cores = 4
#  tailscale_tailnet_key = ""
#  provisioning_script = "./provisioning/k3s_worker.yaml"
#  depends_on = [module.kube-master]
#  networks = [
#    {
#      model = "virtio"
#      bridge = "vmbr0"
#    },
#    {
#      model = "virtio"
#      bridge = "vmbr2"
#      mtu = 9000
#    }
#  ]
#}
