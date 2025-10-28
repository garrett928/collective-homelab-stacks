# Ansible Automation Repo

This repository provides a modular, secure, and repeatable way to manage your infrastructure using Ansible. The structure and instructions below apply to all playbooks in this repo.

---

## Directory Structure

```text
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
│   ├── validate-setup.yml           # Validation playbook (cross-platform)
│   ├── configure-ssh/
│   │   ├── main.yml
│   │   └── vars.yml    # Playbook-specific variables (e.g., ssh_user)
│   ├── ubuntu/
│   │   ├── ubuntu-server-setup.yml  # Main Ubuntu server setup playbook
│   │   ├── install-node-exporter.yml   # Node Exporter installation
│   │   ├── install-promtail.yml        # Promtail log collector installation
│   │   ├── docker-host.yml
│   │   └── proxmox-guest-agent.yml
│   ├── local-setup/
│   │   └── ...
│   └── ...             # Other playbooks, each in their own folder
├── templates/
│   ├── node_exporter.service.j2    # Node Exporter systemd service
│   ├── promtail.service.j2          # Promtail systemd service
│   └── promtail-config.yaml.j2     # Promtail configuration
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

## Configuration Examples

### group_vars/all.yml

```yaml
github_key_url: "https://github.com/garrett928.keys"
ansible_user: root
```

### group_vars/vault.yml (encrypted)

```yaml
become_password: "default_password"
ssh_port: xxxx
```

### host_vars/docker01/vault.yml (encrypted, only if needed)

```yaml
become_password: "special_password"
ssh_port: xxxx
ansible_user: specialuser
```

### playbooks/configure-ssh/vars.yml

```yaml
ssh_user: boptart
```

---

## Ubuntu Server Setup Playbooks

This section contains comprehensive automation for Ubuntu 24.04 server setup, monitoring, and containerization.

### Main Setup Playbook: `ubuntu-server-setup.yml`

**Purpose:** Automation for hardening, monitoring, and configuring Ubuntu servers.

**What it does:**

1. **System Updates & Timezone:**
   - Updates all packages to latest versions
   - Sets timezone to `America/Indiana/Indianapolis` (EST with DST)

2. **Security Hardening:**
   - Changes SSH port (default: 22, customizable via `custom_ssh_port`)
   - Disables password authentication
   - Disables root login
   - Configures UFW firewall (resets existing rules, then applies clean config)
   - Sets up fail2ban with SSH jail protection

3. **Monitoring Stack:**
   - Installs Prometheus Node Exporter (port 9100)
   - Installs Grafana Promtail for log forwarding (port 9080)
   - Configures systemd services for both

4. **System Configuration:**
   - Installs essential packages (vim, git, curl, wget, unzip, fail2ban, ufw)
   - Enables qemu-guest-agent for Proxmox VMs
   - Clones this homelab repository to user's Documents folder
   - installs docker and docker compose

**Prerequisites:**

- Ubuntu 24.04 server (fresh install recommended)
- For Proxmox VMs: qemu-guest-agent must be enabled in VM settings
- Internet connectivity for package downloads
- User with sudo privileges
- ssh keys for ansible already on the ubuntu host

**Usage Examples:**

```bash
# Basic usage (SSH port stays 22, uses default Loki server)
ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml -e "target_hosts=myserver" --ask-become-pass

# With custom SSH port
ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml -e "target_hosts=myserver custom_ssh_port=2222" --ask-become-pass

# With custom Loki server
ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml -e "target_hosts=myserver loki_address=my-loki.example.com" --ask-become-pass
```

**Important Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `custom_ssh_port` | `22` | SSH port to configure |
| `loki_address` | `loki.ghart.space` | Loki server for log forwarding |
| `target_hosts` | `all` | Host group to target |
| `system_username` | `{{ ansible_user }}` | User for repo clone |

**⚠️ Important Notes:**

- **SSH Changes:** After completion, if you changed the SSH port, you'll need to update your SSH connections
- **Reboot Required:** The playbook will tell you to reboot for all changes to take effect
- **UFW Reset:** Existing firewall rules are completely reset and replaced
- **Promtail Group Membership:** User is added to `adm` group for log access - reboot required for this to take effect

---

### 📊 Individual Component Playbooks

#### `install-node-exporter.yml`

**Purpose:** Installs Prometheus Node Exporter for system metrics collection.

**Features:**

- Downloads latest version from GitHub releases
- Creates dedicated `node_exporter` user
- Installs to `/opt/node_exporter/`
- Configures systemd service
- Idempotent (checks version before upgrading)

**Usage:**

```bash
ansible-playbook playbooks/ubuntu/install-node-exporter.yml -i inventories/host-inventory.yml -e "target_hosts=myserver" --ask-become-pass
```

**Verification:**

```bash
# Check service status
sudo systemctl status node_exporter

# Test metrics endpoint
curl http://localhost:9100/metrics
```

#### `install-promtail.yml`

**Purpose:** Installs Grafana Promtail for log forwarding to Loki.

**Features:**

- Downloads latest version from GitHub releases
- Creates dedicated `promtail` user and adds to `adm` group
- Installs to `/opt/promtail/`
- Configures log collection for system logs, auth logs, and fail2ban logs
- Uses templates for configuration

**Usage:**

```bash
# With default Loki server
ansible-playbook playbooks/ubuntu/install-promtail.yml -i inventories/host-inventory.yml -e "target_hosts=myserver" --ask-become-pass

# With custom Loki server
ansible-playbook playbooks/ubuntu/install-promtail.yml -i inventories/host-inventory.yml -e "target_hosts=myserver loki_address=my-loki.example.com" --ask-become-pass
```

**Log Sources Configured:**

- `/var/log/*log` (general system logs)
- `/var/log/syslog` (system messages)
- `/var/log/auth.log` (authentication logs)
- `/var/log/fail2ban.log` (fail2ban logs)

**Verification:**

```bash
# Check service status
sudo systemctl status promtail

# Test metrics endpoint
curl http://localhost:9080/metrics

# Check logs
journalctl -u promtail -f
```

#### `docker-host.yml`

**Purpose:** Installs Docker CE and Docker Compose on Ubuntu 24.04.

**Features:**

- Removes old Docker packages
- Adds official Docker APT repository
- Installs Docker CE, CLI, containerd, buildx, and compose plugins
- Runs hello-world container as verification

**Prerequisites:**

- Must be targeting hosts in `docker-vm` group in inventory
- Ubuntu 24.04 (uses 'noble' repository)

**Usage:**

```bash
ansible-playbook playbooks/ubuntu/docker-host.yml -i inventories/host-inventory.yml --ask-become-pass
```

**Post-Installation:**

```bash
# Add user to docker group (manual step)
sudo usermod -aG docker $USER
# Log out and back in for group membership to take effect
```

#### `proxmox-guest-agent.yml`

**Purpose:** Simple installation of qemu-guest-agent for Proxmox VMs.

**Prerequisites:**

- Must be targeting hosts in `ubuntu-server-24.04` group in inventory
- Proxmox VM with qemu-guest-agent enabled in VM settings

**Usage:**

```bash
ansible-playbook playbooks/ubuntu/proxmox-guest-agent.yml -i inventories/host-inventory.yml --ask-become-pass
```

---

### 🔧 Template Files

The playbooks use Jinja2 templates for configuration:

- **`node_exporter.service.j2`:** Systemd service for Node Exporter
- **`promtail.service.j2`:** Systemd service for Promtail  
- **`promtail-config.yaml.j2`:** Promtail configuration with log scraping rules

---

### 🔍 Troubleshooting

**Common Issues:**

1. **SSH Connection Lost After Port Change:**

   ```bash
   # Connect with new port
   ssh -p NEW_PORT user@hostname
   ```

2. **UFW Blocking Access:**

   ```bash
   # Check UFW status
   sudo ufw status
   # Manually allow port if needed
   sudo ufw allow PORT_NUMBER
   ```

3. **Services Not Starting:**

   ```bash
   # Check service logs
   journalctl -u SERVICE_NAME -f
   # Check service status
   systemctl status SERVICE_NAME
   ```

4. **Promtail Permission Issues:**

   ```bash
   # Verify promtail user is in adm group
   groups promtail
   # If not, reboot the server
   ```

5. **Version Check Failures:**
   - Playbooks auto-detect latest versions from GitHub
   - If GitHub API is unreachable, manually set version variables

**Monitoring Endpoints:**

- Node Exporter: `http://server:9100/metrics`
- Promtail: `http://server:9080/metrics`
- Loki (if running): `http://loki-server:3100`

---

### 📋 Playbook Execution Order

For new server setup, run in this order:

1. `ubuntu-server-setup.yml` (comprehensive setup)
2. `docker-host.yml` (if Docker is needed)
3. Reboot server
4. Verify all services are running

**Or use individual playbooks as needed for specific components.**

---

## Links

- [ansible docs](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [dnf module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/dnf_module.html) - for installing packeges and upgrading the system  
- [ssh key module](https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html)
- [gnome configuration](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_module.html)
  - You'll likely need to install the collection with `ansible-galaxy collection install community.general`
  - [a helpful guide](https://linuxconfig.org/how-to-setup-gnome-using-ansible)
- [Running playbook on localhost](https://www.middlewareinventory.com/blog/run-ansible-playbook-locally/)

## Commands

- `ansible all --list-hosts -i ./host-inventory.yml`  
- `ansible -i inventory-file groupname -m ping --user username --ask-pass`  
    `-m` is for a module, in this case its ping. `--user` is a user on the remote machine  
- `ansible-playbook playbook-path --user username --ask-pass --ask-become-pass -i inventory-file`  this will ask for the ssh password and the sudo password for the user
- `ansible-playbook discord-local-install.yml --user ghart --ask-become-pass` Running a playbook on localhost with become privilege
