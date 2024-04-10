# Configure shell environment
from pyinfra.operations import server, dnf, python
from pyinfra import local

# Provision dns server
local.include("provisioning/user_env.py")

dnf.packages(
    name="Install bind",
    packages=[
        "bind",
        "bind-utils"
    ],
    clean=True
)

# Transfer static/named.conf to /etc/named.conf on the server
server.files.put(
    name="Transfer static/named.conf to /etc/named.conf",
    src="provisioning/static/named.conf",
    dest="/etc/named.conf",
)

# Transfer static/named.rfc1912.zones to /etc/named.rfc1912.zones on the server
server.files.put(
    name="Transfer static/named.rfc1912.zones to /etc/named.rfc1912.zones",
    src="provisioning/static/named.rfc1912.zones",
    dest="/etc/named.rfc1912.zones",
)

# Ensude /etc/bind exists
server.files.directory(
    name="Ensure /etc/bind exists",
    path="/etc/bind/zones",
    present=True,
)

# Transfer static/private.hnatekmar.xyz to /etc/bind/private.hnatekmar.xyz on the server
server.files.put(
    name="Transfer static/private.hnatekmar.xyz to /etc/bind/private.hnatekmar.xyz",
    src="provisioning/static/private.hnatekmar.xyz",
    dest="/etc/bind/zones/private.hnatekmar.xyz",
)

# Start and enable named service
server.service(
    name="Start and enable named service",
    service="named",
    running=True,
    enabled=True
)

# Generate tsig key and insert it to /etc/named.conf
server.shell(
    name="Generate rndc key",
    commands=[
        "tsig-keygen >> /etc/named.conf"
    ],
)