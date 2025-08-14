#!/bin/bash

# Script to create external Docker networks for the homelab
# Run this script before deploying stacks in Portainer

echo "Creating external Docker networks..."

# Create traefik network (shared by all public-facing services)
if ! docker network ls | grep -q "traefik-network"; then
    docker network create traefik-network
    echo "✓ Created traefik-network"
else
    echo "✓ traefik-network already exists"
fi

echo "Network setup complete!"
echo ""
echo "Available networks:"
docker network ls | grep -E "(traefik-network|NETWORK)"
