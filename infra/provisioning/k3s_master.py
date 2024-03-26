import pyinfra
from pyinfra.operations import server

server.shell(
    commands=[
        "curl -sfL https://get.k3s.io | sh -"
    ]
)
