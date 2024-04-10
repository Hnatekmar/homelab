import subprocess

from pyinfra import local
from pyinfra.operations import server, dnf

local.include("provisioning/user_env.py")
local.include("provisioning/nfs.py")

dnf.packages(packages=["rsync", "socat"])

token = subprocess.check_output(["ssh", "-o", "StrictHostKeyChecking no", "-o", "UserKnownHostsFile=/dev/null", "root@k3s-master", "cat /var/lib/rancher/k3s/server/node-token"])
token = token.decode('ascii').strip()

server.shell(
    commands=[f"curl -sfL https://get.k3s.io | K3S_URL=https://k3s-master:6443 K3S_TOKEN={token} sh -"]
)
