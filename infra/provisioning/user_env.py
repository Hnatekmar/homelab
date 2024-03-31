# Configure shell environment
from pyinfra.operations import server, dnf, python


def configure_shell_env():
    """
    Configure shell environment
    """
    dnf.packages(
        name="Install fish",
        packages=[
            "fish",
            "nmap",
            "btop",
            "fzf",
            "ripgrep",
            "dnf-plugins-core",
            "qemu-guest-agent",
        ],
    )
    server.shell(name="Set fish as default shell", commands=["chsh -s /usr/bin/fish"])


python.call(
    name="Configure shell environment",
    function=configure_shell_env,
)
