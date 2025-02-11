# Ansible

Automation with ansible

## Links

- [ansible docs](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [dnf module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/dnf_module.html) - for installing packeges and upgrading the system  
- [ssh key module](https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html)
- [gnome configuration](https://docs.ansible.com/ansible/latest/collections/community/general/gconftool2_module.html)
  - You'll likely need to install the collection with `ansible-galaxy collection install community.general`
  - [a helpful guide](https://linuxconfig.org/how-to-setup-gnome-using-ansible)
- [Running playbook on localhost](https://www.middlewareinventory.com/blog/run-ansible-playbook-locally/)

## Commands

- `ansible all --list-hosts -i ./host-inventory.ini`  
- `ansible -i inventory-file groupname -m ping --user username --ask-pass`  
    `-m` is for a module, in this case its ping. `--user` is a user on the remote machine  
- `ansible-playbook playbook-path --user username --ask-pass --ask-become-pass -i inventory-file`  this will ask for the ssh password and the sudo password for the user
- `ansible-playbook discord-local-install.yml --user ghart --ask-become-pass` Running a playbook on localhost with become privilege

## TODO

- make the discord install tasks grab the version of fedora from the previous tasks and install the correct version of the RPM fusion repo
