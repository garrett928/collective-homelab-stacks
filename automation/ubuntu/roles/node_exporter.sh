#!/bin/bash
set -euxo pipefail

# Get latest version
LATEST=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/v//')
NODE_EXPORTER_VERSION=${LATEST}

if ! id -u node_exporter &>/dev/null; then
  useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true
fi
mkdir -p /opt/node_exporter
cd /opt/node_exporter
if [ ! -f node_exporter ]; then
  curl -sSL -O https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
  tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
  cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter .
  rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*
  chown node_exporter:node_exporter node_exporter
  chmod 755 node_exporter
fi
cp $(dirname "$0")/../systemd/node_exporter.service /etc/systemd/system/node_exporter.service
systemctl daemon-reload
systemctl enable --now node_exporter
