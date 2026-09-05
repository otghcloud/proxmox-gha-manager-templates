#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

sudo cloud-init clean
sudo rm -f /etc/ssh/ssh_host_*
sudo truncate -s 0 /etc/machine-id
echo "==> Done"
