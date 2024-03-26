import pyinfra
from pyinfra import local
from pyinfra.operations import server, python, dnf

local.include("provisioning/utils.py")

dnf.packages(
    packages=[
        "rsync"
    ]
)

server.shell(
    commands=[
        "curl -sfL https://get.k3s.io | sh -s - server --node-taint CriticalAddonsOnly=true:NoExecute",
        "rsync -avP /nfs/work/kube/*.y*ml /var/lib/rancher/k3s/server/manifests"
    ]
)
