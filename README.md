# collective-homelab-stacks

A collection of homelab docker files, k8s manifest, and ansible playbooks.

## Organization

Each grouping of software is in its own folder under the this root folder.

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
