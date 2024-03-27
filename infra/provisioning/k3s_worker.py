import os

from pyinfra import local
from pyinfra.operations import server

local.include("provisioning/utils.py")

url = os.environ["K3S_URL"]
token = os.environ["K3S_TOKEN"]

server.shell(
    commands=[
        f"curl -sfL https://get.k3s.io | K3S_URL={url} K3S_TOKEN={token} sh -"
    ]
)
