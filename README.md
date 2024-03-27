# Usage

- Provision one or more proxmox nodes (tested on proxmox 8.1)
- If you provisioned multiple nodes you should connect them to cluster
- Prepare template base for vms and distribute it to all nodes (tested on https://fedoraproject.org/cloud/download (version 39)) it should be called `fedora-server-base`
- Create `.env` file inside ./infra (use `.env.example` as template)
- run `go-task up` in order to provision infra
