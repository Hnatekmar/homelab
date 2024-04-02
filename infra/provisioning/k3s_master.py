from pyinfra import local
from pyinfra.operations import server, dnf

local.include("provisioning/user_env.py")
local.include("provisioning/nfs.py")

dnf.packages(packages=["rsync", "socat"])

server.shell(
    commands=[
        "curl -sfL https://get.k3s.io | sh -s - server --node-taint CriticalAddonsOnly=true:NoExecute"
    ]
)
