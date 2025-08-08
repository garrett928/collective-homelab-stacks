# Ubuntu Automated Install & Modular Setup

>This directory provides a fully automated, modular, and idempotent Ubuntu installation and post-install configuration system for homelab and server environments.

## Overview

This system leverages Ubuntu's autoinstall (cloud-init) mechanism to:
- Automate the OS install with secure defaults
- Configure SSH with key-only authentication (fetches keys from your GitHub)
- Set up a user (`bomato` by default, but prompts for override and password)
- Install and configure essential packages and security tools
- Set up and enable UFW, fail2ban, and qemu-guest-agent
- Install and configure Prometheus node_exporter and Grafana promtail for metrics and log shipping
- Clone this repository to the user's Documents folder
- Run a modular, idempotent setup script that can be extended with new roles

## Directory Structure

```
automation/ubuntu/
├── autoinstall.yaml         # Main Ubuntu autoinstall config
├── setup.sh                # Main orchestrator script (calls roles/*)
├── roles/                  # Modular scripts for each setup task
│   ├── base.sh
│   ├── guest_agent.sh
│   ├── node_exporter.sh
│   └── promtail.sh
├── configs/
│   └── promtail-config.yaml
├── systemd/
│   ├── node_exporter.service
│   └── promtail.service
└── readme.md               # This documentation
```

## How It Works

### 1. Ubuntu Autoinstall
- The `autoinstall.yaml` file is used by the Ubuntu installer (Subiquity) to automate the installation process.
- It configures SSH, user, packages, firewall, and fetches my SSH keys from GitHub.
- It clones this repo to the Documents folder and runs `setup.sh` as the final step.

### 2. Modular Setup Script
- `setup.sh` logs all output to `/var/log/setup.log` and is safe to rerun (idempotent).
- It calls each script in `roles/` in order:
  - `base.sh`: Placeholder for any base system setup
  - `guest_agent.sh`: Enables qemu-guest-agent
  - `node_exporter.sh`: Installs the latest node_exporter, sets up systemd service
  - `promtail.sh`: Installs the latest promtail, sets up config and systemd service
- Service files and configs are kept in `systemd/` and `configs/` for clarity and easy modification.

### 3. Metrics & Logs
- Node exporter and promtail are installed from the latest GitHub releases at runtime (no hardcoded versions).
- Promtail is configured to send logs to a Loki server, address set by the `LOKI_ADDRESS` environment variable (defaults to `loki.ghart.space`).

## How to Use

### 1. Prepare the Install Media
- Place `autoinstall.yaml` in the correct location for your Ubuntu install method (USB, ISO, PXE, etc.).
  - See Ubuntu docs for details: https://ubuntu.com/server/docs/install/autoinstall

### 2. Customize Before Install
- **User**: Change the default username in `autoinstall.yaml` if desired.
- **SSH Keys**: By default, keys are fetched from `https://github.com/garrett928.keys`. Change the URL in `autoinstall.yaml` if needed.
- **Packages**: Add/remove packages in the `packages:` section of `autoinstall.yaml`.
- **Firewall/Ports**: Adjust UFW rules in the `late-commands` section if you want to allow/deny different ports.
- **Loki Address**: To change the Loki server, set the `LOKI_ADDRESS` environment variable before running `setup.sh`, or edit the default in `promtail-config.yaml`.
- **Add More Roles**: Add new scripts to `roles/` and call them from `setup.sh` to extend functionality.

### 3. Run the Install
- Boot the target machine with the prepared install media.
- The installer will prompt for the username and password (with defaults), then proceed automatically.
- After install, the system will reboot, and all post-install setup will be handled by `setup.sh`.

### 4. Post-Install
- All logs from the setup process are in `/var/log/setup.log`.
- Node exporter and promtail will be running as systemd services.
- The repository will be cloned to `~/Documents/collective-homelab-stacks` for the created user.

## How to Modify or Extend

- **Add a new setup step**: Create a new script in `roles/` (e.g., `roles/my_custom.sh`), make it executable, and add a call to it in `setup.sh`.
- **Change service configs**: Edit files in `systemd/` or `configs/` and rerun `setup.sh`.
- **Update Promtail/Node Exporter**: The scripts always fetch the latest release, so no version bump is needed.
- **Change logging or metrics targets**: Edit `promtail-config.yaml` or the relevant role script.

## Troubleshooting

- If a service fails to start, check `/var/log/setup.log` and `systemctl status <service>`.
- If you need to rerun the setup, just run `sudo ./setup.sh` again.
- All scripts are idempotent and safe to rerun.

## References

- [Ubuntu Autoinstall Docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html)
- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [Grafana Loki & Promtail](https://github.com/grafana/loki)
