from pyinfra import local
from pyinfra.operations import dnf

local.include("provisioning/user_env.py")

dnf.packages(
    packages=["nginx"],
)
