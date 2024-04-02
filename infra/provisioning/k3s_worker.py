import os

from pyinfra import local
from pyinfra.operations import server, dnf

local.include("provisioning/user_env.py")
local.include("provisioning/nfs.py")

token = os.environ["K3S_TOKEN"]
dnf.packages(packages=["rsync", "socat"])

server.shell(
    commands=[f"curl -sfL https://get.k3s.io | K3S_URL=https://k3s-master:6443 K3S_TOKEN={token} sh -"]
)
