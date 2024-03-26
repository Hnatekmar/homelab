# Defines common operations
from pyinfra.api import operation
from pyinfra.operations import dnf, files, server, python


def connect_to_nas():
    """
    Connects server to nas and mounts directories to it
    """
    # Install nfs utils
    dnf.packages(
        # name="Install nfs utils",
        packages=["nfs-utils"],
    )
    mounts = [
        "work"
    ]
    files.line(
        # name="Insert nas.hnatekmar.xyz to /etc/hosts",
        path="/etc/hosts",
        line="192.168.88.10 nas.hnatekmar.xyz"
    )
    files.directory(
        # name="Create /nfs",
        path="/nfs"
    )
    for mount in mounts:
        files.line(
            # name="Insert mount to /etc/fstab",
            path="/etc/fstab",
            line="nas.hnatekmar.xyz:/" + mount + f"\t/nfs/{mount}\tnfs\tx-systemd.automount\t" + "0\t" + "0",
        )
        server.shell(
            commands=[
                "systemctl daemon-reload",
                f"systemctl start nfs-{mount}.mount"
            ]
        )


python.call(
    name="Generate /etc/fstab for nas",
    function=connect_to_nas
)
