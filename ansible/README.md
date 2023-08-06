# Ansible
Automation with ansible

# Links

 - [ansible docs](https://docs.ansible.com/ansible/latest/getting_started/index.html)
 - [dnf module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/dnf_module.html) - for installing packeges and upgrading the system

 # Commands

 - `ansible all --list-hosts -i ./host-inventory.ini`  
 - `ansible -i inventory-file groupname -m ping --user username --ask-pass`  
    `-m` is for a module, in this case its ping. `--user` is a user on the remote machine  
- `ansible-playbook playbook-path --user username --ask-pass --ask-become-pass -i inventory-file`  
