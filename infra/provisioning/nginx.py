from pyinfra.operations import dnf, systemd

dnf.packages(
    name="Install nginx",
    packages=["nginx"]
)

systemd.service(
    name="Start nginx",
    service="nginx",
    running=True,
    enabled=True
)
