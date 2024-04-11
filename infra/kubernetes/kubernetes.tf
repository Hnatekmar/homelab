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

variable "gpu_worker_nodes" {
  description = "List of proxmox nodes to deploy VMs on"
  type        = list(string)
  default     = ["gpve-0"]
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

module "kube-worker-gpu" {
  depends_on = [dns_a_record_set.kube-master-dns]
  providers = {
    proxmox = proxmox
  }
  template = "fedora-server-39-gpu"
  for_each = toset(var.gpu_worker_nodes)
  source = "./vm"
  name = "k3s-worker-${each.value}.private.hnatekmar.xyz"
  node = each.value
  private_ssh_key = var.ssh_key
  provisioning_script = "./provisioning/k3s_worker.yaml"
  ipconfig0 = "ip=dhcp"
  memory = 16192
  disk_size = 32
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

resource "dns_a_record_set" "kube-worker-gpu-dns" {
  depends_on = [module.kube-worker-gpu]
  for_each = toset(var.gpu_worker_nodes)
  addresses = [module.kube-worker-gpu[each.value].ip]
  zone      = "private.hnatekmar.xyz."
  name = "k3s-worker-${each.value}"
}
