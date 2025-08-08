# Ansible Automation Repo

This repository provides a modular, secure, and repeatable way to manage your infrastructure using Ansible. The structure and instructions below apply to all playbooks in this repo.

---

## Directory Structure

```
ansible/
├── inventories/
│   └── host-inventory.yml
├── group_vars/
│   ├── all.yml         # Non-sensitive, global variables (e.g., github_key_url, ansible_user)
│   └── vault.yml       # Encrypted with ansible-vault, holds default become_password and ssh_port
├── host_vars/
│   └── HOSTNAME/
│       └── vault.yml   # (Optional) Encrypted, only for hosts that need to override defaults (including ansible_user)
├── playbooks/
│   ├── configure-ssh/
│   │   ├── main.yml
│   │   └── vars.yml    # Playbook-specific variables (e.g., ssh_user)
│   └── ...             # Other playbooks, each in their own folder
└── README.md
```

---

## 1. Setting Up Your Inventory
- Edit `inventories/host-inventory.yml` to add your hosts.
- Example:
  ```yaml
  myserver:
    hosts:
      192.168.1.100:
        ansible_user: root
  ```

---

## 2. Setting Up Variables
- **Global variables:**
  - Edit `group_vars/all.yml` for non-sensitive settings (e.g., `github_key_url`, `ansible_user`).
- **Sensitive variables (vault):**
  - Edit `group_vars/vault.yml` for defaults (e.g., `become_password`, `ssh_port`).
  - (Optional) Create `host_vars/HOSTNAME/vault.yml` for per-host overrides.
- **Playbook-specific variables:**
  - Edit `playbooks/PLAYBOOK/vars.yml` as needed.

---

## 3. Using Ansible Vault
- **Create a vault file:**
  ```sh
  ansible-vault create group_vars/vault.yml
  # or for a host override
  ansible-vault create host_vars/HOSTNAME/vault.yml
  ```
- **Edit a vault file:**
  ```sh
  ansible-vault edit group_vars/vault.yml
  ```
- **View a vault file:**
  ```sh
  ansible-vault view group_vars/vault.yml
  ```
- **Encrypt an existing file:**
  ```sh
  ansible-vault encrypt group_vars/vault.yml
  ```
- **Decrypt a file:**
  ```sh
  ansible-vault decrypt group_vars/vault.yml
  ```

---

## 4. Running a Playbook
- Use the following command:
  ```sh
  ansible-playbook -i inventories/host-inventory.yml playbooks/PLAYBOOK/main.yml --ask-vault-pass
  ```
- Replace `PLAYBOOK` with the folder name of the playbook you want to run.

---

## 5. Handling Password vs. Key-Based SSH Login

**Ansible does not automatically fall back from key-based to password-based authentication.**

- By default, Ansible will try to use SSH key-based authentication as configured in your inventory or variable files.
- If key-based login fails (for example, on a freshly provisioned host that only allows password login), you must manually instruct Ansible to use password-based authentication.

**How to do this:**

- **First, try key-based login:**
  ```sh
  ansible-playbook -i inventories/host-inventory.yml playbooks/PLAYBOOK/main.yml --ask-vault-pass
  ```
- **If that fails, use password-based login:**
  ```sh
  ansible-playbook -i inventories/host-inventory.yml playbooks/PLAYBOOK/main.yml --ask-pass --ask-become-pass --ask-vault-pass
  ```
  - `--ask-pass` will prompt for the SSH password.
  - `--ask-become-pass` will prompt for the sudo password.

**Once the playbook has set up SSH keys, you can use key-based login for all future runs.**

---

## 6. First-Time Setup: Bootstrapping a Host

**Step 1:**
- Run the SSH setup playbook (`configure-ssh`) as `root` (or the initial user) to create a new, secure user and harden SSH.
- Example:
  ```sh
  ansible-playbook -i inventories/host-inventory.yml playbooks/configure-ssh/main.yml --ask-vault-pass
  ```
  - If this fails, re-run with `--ask-pass --ask-become-pass` as described above.

**Step 2:**
- Update your inventory or host/group vars to set `ansible_user` to the new user you just created.
- All future playbooks should use this new user for improved security.

---

## 6. Notes
- Only create per-host vault files if you need to override the default for a specific host.
- After running the configure-ssh playbook, update your inventory or group/host vars to use the new user for future playbooks.
- All playbooks in this repo follow this structure for maximum clarity and repeatability.

## Variable Management
- `group_vars/all.yml`: Global, non-sensitive variables (e.g., `github_key_url`, `ansible_user`)
- `group_vars/vault.yml`: Default sensitive variables (e.g., `become_password`, `ssh_port`) (encrypted with Ansible Vault)
- `host_vars/HOSTNAME/vault.yml`: Per-host overrides for sensitive variables (only if needed, encrypted)
- `playbooks/configure-ssh/vars.yml`: Playbook-specific variables (e.g., `ssh_user`)

## Usage
1. **Add hosts** to `inventories/host-inventory.yml`.
2. **Set global variables** in `group_vars/all.yml`.
3. **Set default sensitive variables** in `group_vars/vault.yml` (encrypt with `ansible-vault`).
4. **(Optional) Set per-host overrides** in `host_vars/HOSTNAME/vault.yml` (encrypt with `ansible-vault`).
5. **Set playbook-specific variables** in `playbooks/configure-ssh/vars.yml`.
6. **Run the playbook:**
   ```sh
   ansible-playbook -i inventories/host-inventory.yml playbooks/configure-ssh/main.yml --ask-vault-pass
   ```
7. **After initial setup**, update `ansible_user` in `group_vars/all.yml` or in `host_vars/HOSTNAME/vault.yml` to use the new user for future playbooks.

## Example: group_vars/all.yml
```yaml
github_key_url: "https://github.com/garrett928.keys"
ansible_user: root
```

## Example: group_vars/vault.yml (encrypted)
```yaml
become_password: "default_password"
ssh_port: xxxx
```

## Example: host_vars/docker01/vault.yml (encrypted, only if needed)
```yaml
become_password: "special_password"
ssh_port: xxxx
ansible_user: specialuser
```

## Example: playbooks/configure-ssh/vars.yml
```yaml
ssh_user: boptart
```

## Links

- [ansible docs](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [dnf module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/dnf_module.html) - for installing packeges and upgrading the system  
- [ssh key module](https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html)
- [gnome configuration](https://docs.ansible.com/ansible/latest/collections/community/general/gconftool2_module.html)
  - You'll likely need to install the collection with `ansible-galaxy collection install community.general`
  - [a helpful guide](https://linuxconfig.org/how-to-setup-gnome-using-ansible)
- [Running playbook on localhost](https://www.middlewareinventory.com/blog/run-ansible-playbook-locally/)

## Commands

- `ansible all --list-hosts -i ./host-inventory.yml`  
- `ansible -i inventory-file groupname -m ping --user username --ask-pass`  
    `-m` is for a module, in this case its ping. `--user` is a user on the remote machine  
- `ansible-playbook playbook-path --user username --ask-pass --ask-become-pass -i inventory-file`  this will ask for the ssh password and the sudo password for the user
- `ansible-playbook discord-local-install.yml --user ghart --ask-become-pass` Running a playbook on localhost with become privilege