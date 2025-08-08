#!/bin/bash
set -euxo pipefail
systemctl enable --now qemu-guest-agent
