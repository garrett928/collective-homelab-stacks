#!/bin/bash
exec > >(tee /var/log/setup.log) 2>&1
set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run modular roles
"$SCRIPT_DIR/roles/base.sh"
"$SCRIPT_DIR/roles/guest_agent.sh"
"$SCRIPT_DIR/roles/node_exporter.sh"
"$SCRIPT_DIR/roles/promtail.sh"
