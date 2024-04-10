from pyinfra import local
from pyinfra.operations import server, dnf

local.include("../common/user_env.py")
local.include("../common/nfs.py")

dnf.packages(packages=["rsync", "socat"])

server.shell(
    commands=[
        "curl -sfL https://get.k3s.io | sh -s - server --node-taint CriticalAddonsOnly=true:NoExecute"
    ]
)
