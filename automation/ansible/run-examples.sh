#!/bin/bash

# Ubuntu Server Setup - Quick Start Script
# This script provides examples of how to run the Ubuntu server setup playbooks

echo "Ubuntu Server Setup - Ansible Playbooks"
echo "========================================"
echo ""

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible is not installed. Please install ansible first:"
    echo "   pip install ansible"
    echo "   or"
    echo "   brew install ansible"
    exit 1
fi

echo "Available commands:"
echo ""
echo "1. Full Ubuntu Server Setup (default settings):"
echo "   ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml"
echo ""
echo "2. Full Ubuntu Server Setup with custom SSH port:"
echo "   ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml -e \"custom_ssh_port=2222\""
echo ""
echo "3. Full Ubuntu Server Setup with custom Loki server:"
echo "   ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml -e \"loki_address=my-loki.example.com\""
echo ""
echo "4. Node Exporter only:"
echo "   ansible-playbook playbooks/ubuntu/install-node-exporter.yml -i inventories/host-inventory.yml"
echo ""
echo "5. Promtail only:"
echo "   ansible-playbook playbooks/ubuntu/install-promtail.yml -i inventories/host-inventory.yml"
echo ""
echo "6. Target specific host group:"
echo "   ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml --limit docker_vm"
echo ""
echo "Default values:"
echo "  - SSH Port: 5188"
echo "  - Loki Server: loki.ghart.space"
echo "  - Target: all hosts"
echo ""
echo "Before running, make sure to:"
echo "1. Update inventories/host-inventory.yml with your hosts"
echo "2. Ensure SSH key authentication is set up"
echo "3. Test connectivity: ansible all -i inventories/host-inventory.yml -m ping"
echo ""

# If arguments provided, show help for specific command
if [ "$1" = "help" ]; then
    echo "Usage examples:"
    echo ""
    echo "Test connectivity:"
    echo "  ansible all -i inventories/host-inventory.yml -m ping"
    echo ""
    echo "Run with verbose output:"
    echo "  ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml -v"
    echo ""
    echo "Dry run (check mode):"
    echo "  ansible-playbook playbooks/ubuntu/ubuntu-server-setup.yml -i inventories/host-inventory.yml --check"
    echo ""
fi
