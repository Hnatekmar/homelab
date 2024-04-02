module "public-proxy" {
  source = "./vm"
  name = "public-proxy"
  node = "pve-0"
  ipconfig0 = "ip=172.16.100.20/24,gw=172.16.100.1"
  tailscale_tailnet_key = tailscale_tailnet_key.tailnet_key.key
  cores = 2
  memory = 2048
  provisioning_script = "./provisioning/public_proxy.py"
}