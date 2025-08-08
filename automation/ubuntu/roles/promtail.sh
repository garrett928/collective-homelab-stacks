#!/bin/bash
set -euxo pipefail

# Get latest version
LATEST=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/v//')
PROMTAIL_VERSION=${LATEST}
LOKI_ADDRESS="${LOKI_ADDRESS:-loki.ghart.space}"

if ! id -u promtail &>/dev/null; then
  useradd --no-create-home --shell /usr/sbin/nologin promtail || true
fi
mkdir -p /opt/promtail
cd /opt/promtail
if [ ! -f promtail ]; then
  curl -sSL -O https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
  unzip promtail-linux-amd64.zip
  mv promtail-linux-amd64 promtail
  rm promtail-linux-amd64.zip
  chmod +x promtail
  chown promtail:promtail promtail
fi
cp $(dirname "$0")/../configs/promtail-config.yaml /opt/promtail/promtail-config.yaml
cp $(dirname "$0")/../systemd/promtail.service /etc/systemd/system/promtail.service
systemctl daemon-reload
systemctl enable --now promtail
