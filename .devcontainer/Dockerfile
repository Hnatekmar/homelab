# Dev environment for homelab
FROM fedora:39

RUN dnf -y update && \
    dnf install -y go-task python3-pip dnf-plugins-core && \
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo && \
    dnf -y install terraform && \
    dnf clean all -y

RUN python3 -m pip install pyinfra
