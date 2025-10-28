# Homelab Deployment Guide

This guide covers the complete setup of my homelab infrastructure using Infrastructure as Code (IaC) principles.

## Prerequisites

- Ubuntu server with SSH access
- Ansible installed on your control machine
- This repository cloned to your control machine

## Step 1: Server Setup

1. **Configure Ansible inventory**:
   ```bash
   # Edit the inventory file
   nano automation/ansible/inventories/host-inventory.yml

   # Update with your server details:
   # - IP address
   # - Username
   # - SSH key path
   ```

2. **Install Docker and Portainer**:
   ```bash
   cd automation/ansible

   # Install Docker
   ansible-playbook ./playbooks/ubuntu/docker-host.yml --ask-become-pass -i ./inventories/host-inventory.yml

   # Deploy Portainer with Traefik
   ansible-playbook ./playbooks/deploy-portainer.yml --ask-become-pass -i ./inventories/host-inventory.yml
   ```

## Step 2: Network Setup

1. **Create external networks**:
   ```bash
   # Run on your Docker host
   ./scripts/setup-networks.sh
   ```

   This creates the `traefik-network` that all services use for external access.

## Step 3: Configure DNS

Add these DNS entries (via your router/DNS provider):

```
portainer.ghart.space   → [your-server-ip]
grafana.ghart.space     → [your-server-ip]
prometheus.ghart.space  → [your-server-ip]
metrics.ghart.space     → [your-server-ip]
dashy.ghart.space       → [your-server-ip]
bookstack.ghart.space   → [your-server-ip]
influxdb.ghart.space    → [your-server-ip]
uptime.ghart.space      → [your-server-ip]
monica.ghart.space      → [your-server-ip]
```

## Step 4: Deploy Stacks

1. **Access Portainer**: Navigate to `https://portainer.ghart.space`

2. **Configure GitOps**:
   - Go to GitOps → Add repository
   - Add this repository URL
   - Configure authentication if needed

3. **Deploy stacks** in this order:
   1. **Monitoring Stack** (`prometheus/docker-compose.yml`)
   2. **Grafana** (`grafana/docker-compose.yml`)
   3. **Other services** as needed

## Step 5: Verify Deployment

1. **Check services**:
   - Portainer: `https://portainer.ghart.space`
   - Prometheus: `https://prometheus.ghart.space`
   - Grafana: `https://grafana.ghart.space`
   - Metrics: `https://metrics.ghart.space/nodeexporter/metrics`

2. **Verify network isolation**:
   ```bash
   # Each stack should have its own internal network
   docker network ls | grep internal
   ```

## Architecture Overview

### Network Security
- **Internal Networks**: Each stack uses isolated internal networks
- **External Access**: Only through Traefik reverse proxy
- **Metrics**: Centralized at `metrics.ghart.space` with path-based routing

### Service Discovery
- **Public Services**: Routed via Traefik with Let's Encrypt certificates
- **Metrics Endpoints**:
  - Node Exporter: `/nodeexporter/metrics`
  - cAdvisor: `/cadvisor/metrics`

### Security Benefits
- ✅ No lateral movement between services
- ✅ Centralized SSL termination
- ✅ No direct port exposure
- ✅ All configuration in Git

## Troubleshooting

1. **Network issues**: Ensure `traefik-network` exists
2. **SSL certificates**: Check Traefik logs for Let's Encrypt issues
3. **Service access**: Verify DNS resolution and Traefik routing rules
4. **Metrics**: Test endpoints directly via `curl https://metrics.ghart.space/nodeexporter/metrics`
