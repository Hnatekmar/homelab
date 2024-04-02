from pyinfra import local
from pyinfra.operations import dnf, systemd, files

local.include("provisioning/user_env.py")

dnf.packages(
    packages=["nginx"]
)

files.put(
    name="Upload nginx configuration",
    dest="/etc/nginx/nginx.conf",
    src="./provisioning/static/public-nginx.conf"
)

systemd.service(
    name="nginx",
    service="nginx",
    running=True,
    restarted=True,
    enabled=True
)
