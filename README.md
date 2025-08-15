# collective-homelab-stacks

A collection of homelab docker files, k8s manifest, and ansible playbooks.

## Organization

Each grouping of software is in its own folder under the this root folder. Some of these projects, like finance are only one application. Most of these folders are only just a simple docker compose.

## Monitoring

The monitoring architecture follows a secure, network-isolated approach:

- **Each stack** uses its own internal network (e.g., `prometheus-internal`, `grafana-internal`)
- **Metrics endpoints** are exposed via Traefik at `metrics.ghart.space` with path-based routing:
  - Node Exporter: `https://metrics.ghart.space/nodeexporter/metrics`
  - cAdvisor: `https://metrics.ghart.space/cadvisor/metrics`
- **Only Traefik** has access to both internal networks and external traffic
- **No direct port publishing** for monitoring services (everything goes through Traefik)

## Portainer

Portainer has this nice feature to define ENVs when you make a stack that are outside of your compose file but can still be used by your services. I am trying to use a gitops still workflow as much as possible, so I want everything to be tracked by git. I don't want to manually put things into portainer. The only thing portainer should do it pull from my github. However, in regards to passwords, many services which are "dockerized" want you to supply a password or other critical information via ENV. If these are tracked with git then I have two options: make the repo private or publish my password to the internet. I don't like either of those. 

The problem was the ENV feature in portainer was not documented and I could not get it to work. I [finally found the portainer ENV docs](https://www.portainer.io/blog/using-env-files-in-stacks-with-portainer).

`NOTE: The stack.env file feature from the above docs still does note work. But the individual variables do.`

## Docker / Portainer Installation
This installation will walk through installing docker and portainer on a Ubuntu machine (or VM). This does not discuss how to setup the Ubuntu machine.

### Requirements

- A machine with this repo cloned. We'll call this the `ansible host`
- A machine with a fresh install of ubuntu server installed. We'll call this the `ansible target`
- Ansible installed on the ansible host.

### Setting up ansible

The ansible playbooks expect that a ssh key called "ansible" exist on the ansible host. This ssh key will be used by the playbooks to remote into the ansible target.

1. Create a ssh key called "ansible" on the ansible host
2. Copy the ansible ssh public key to the ansible target
3. Verify you can ssh into the ansible target using this key
4. Update the `ansible/inventories/host-inventory.yml` file

    - update the username for the server
    - update the ip address of the server
    - update the file path to the ansible ssh key if needed

### Installing Docker and Portainer

1. Open the ansible directory of this repo in a terminal on the ansible host
2. Install docker to the ansible target with `ansible-playbook ./playbooks/ubuntu/docker-host.yml --ask-become-pass -i ./
inventories/host-inventory.yml`. You will be prompted for the account password of the server.
3. Install protainer to the ansible target with `ansible-playbook ./playbooks/deploy-portainer.yml --ask-become-pass -i ./inventories/host-inventory.yml`. You will be prompted for the account password of the server.

## TODO

- Add authentication/authorization to metrics endpoints
- Document secrets management workflow
- Add health checks to all services
- use `ghart.space` domain cert