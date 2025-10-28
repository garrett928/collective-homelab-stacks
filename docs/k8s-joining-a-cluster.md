# Joining a New Node to the K3s Cluster

This guide walks you through the process of adding a new node to your existing K3s cluster using Ansible playbooks.

## Prerequisites

Before starting, ensure you have:

1. **New Ubuntu Server** (physical or virtual machine)
   - Ubuntu 24.04 LTS recommended
   - Minimum 2 CPU cores, 4GB RAM
   - Static IP address configured
   - Network connectivity to existing cluster nodes

2. **SSH Access Configured**
   - SSH keys already set up for passwordless authentication
   - User account with sudo privileges
   - SSH service running and accessible

3. **Ansible Control Node**
   - Ansible installed on your local machine or control node
   - Access to this repository: `collective-homelab-stacks`
   - Inventory file updated with the new node

## Overview

The process consists of several layers that build upon each other:

1. **Ubuntu Base Setup** - Core system configuration, SSH hardening, firewall, monitoring
2. **K3s Prerequisites** - Firewall rules and system requirements for K3s
3. **K3s Installation** - Install K3s with HA configuration
4. **Join Cluster** - Connect the new node to your existing cluster
5. **Post-Install** - Deploy core services (Longhorn, ArgoCD)

## Step-by-Step Instructions

### Step 1: Update Ansible Inventory

Add your new node to the inventory file at `automation/ansible/inventories/homelab.yml`:

```yaml
all:
  children:
    k8s_nodes:
      hosts:
        b8s-01:
          ansible_host: 192.168.1.10
        b8s-02:
          ansible_host: 192.168.1.11
        b8s-03:
          ansible_host: 192.168.1.12
        b8s-04:  # Your new node
          ansible_host: 192.168.1.13
          ansible_user: k8s-admin
```

### Step 2: Verify SSH Connectivity

Test that Ansible can connect to the new node:

```bash
cd automation/ansible
ansible -i inventories/homelab.yml b8s-04 -m ping
```

### Step 3: Run Ubuntu Base Setup

This playbook configures the base Ubuntu system including SSH hardening, firewall, fail2ban, monitoring (Node Exporter, Promtail), and Docker.

```bash
ansible-playbook -i inventories/homelab.yml \
  playbooks/ubuntu/ubuntu-server-setup.yml \
  --limit b8s-04
```

**What this does:**

- Sets timezone to America/Indiana/Indianapolis
- Installs essential packages (curl, git, vim, htop, etc.)
- Configures SSH (disables password auth, disables root login)
- Sets up UFW firewall with basic rules
- Installs and configures fail2ban
- Enables qemu-guest-agent (for VMs)
- Installs Prometheus Node Exporter
- Installs Grafana Promtail for log shipping
- Installs Docker and Docker Compose

**Note:** You may need to reconnect via SSH if the SSH port was changed.

### Step 4: Run K3s Prerequisites

This playbook configures the firewall rules specific to K3s cluster networking:

```bash
ansible-playbook -i inventories/homelab.yml \
  playbooks/layers/03-k3s-prerequisites.yml \
  --limit b8s-04
```

**What this does:**

- Opens port 6443 (Kubernetes API server)
- Allows pod network traffic (10.42.0.0/16)
- Allows service network traffic (10.43.0.0/16)
- Opens port 10250 (Kubelet)
- Opens port 51820-51821 (WireGuard for Flannel)
- Opens ports 2379-2380 (etcd for HA)

### Step 5: Get Cluster Join Token

Before joining the node, you need to retrieve the join token from an existing cluster node.

#### Option A: Manual Token Retrieval

SSH into one of your existing cluster nodes (e.g., b8s-01) and run:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Save this token - you'll need it for the next step.

#### Option B: Using Ansible to Save Join Info

Run this command to save the join information to a local file:

```bash
ansible -i inventories/homelab.yml b8s-01 \
  -m shell \
  -a "echo 'K3S_URL=https://{{ ansible_host }}:6443' && echo 'K3S_TOKEN='$(sudo cat /var/lib/rancher/k3s/server/node-token)" \
  --become \
  | grep -E 'K3S_URL|K3S_TOKEN' > k3s-join-info.txt
```

### Step 6: Join Node to Cluster

Now join the new node to your existing K3s cluster:

#### Using the Join Playbook

If you haven't already, create a `k3s-join-info.txt` file:

```bash
ansible-playbook -i inventories/homelab.yml \
  playbooks/k8s/join-cluster.yml \
  --limit b8s-04
```

### Step 7: Verify Node Joined Successfully

From any existing cluster node or your local machine (with kubectl configured), verify the new node:

```bash
kubectl get nodes
```

Expected output should show all nodes including the new one:

```text
NAME     STATUS   ROLES                       AGE     VERSION
b8s-01   Ready    control-plane,etcd,master   30d     v1.28.5+k3s1
b8s-02   Ready    control-plane,etcd,master   30d     v1.28.5+k3s1
b8s-03   Ready    control-plane,etcd,master   30d     v1.28.5+k3s1
b8s-04   Ready    control-plane,etcd,master   2m      v1.28.5+k3s1
```

Wait for the status to change from `NotReady` to `Ready` (may take 1-2 minutes).

## Post-Join Configuration

### Verify Longhorn

If Longhorn is installed, verify it recognizes the new node:

```bash
kubectl get nodes -n longhorn-system -o wide
```

### Label Nodes (Optional)

Add labels to the new node for workload scheduling:

```bash
# Example: Label for specific workloads
kubectl label node b8s-04 node-role.kubernetes.io/worker=worker

# Example: Label for storage
kubectl label node b8s-04 node.longhorn.io/create-default-disk=true
```

### Verify Storage

Check that Longhorn has created disks on the new node:

```bash
kubectl get nodes.longhorn.io -n longhorn-system
```
