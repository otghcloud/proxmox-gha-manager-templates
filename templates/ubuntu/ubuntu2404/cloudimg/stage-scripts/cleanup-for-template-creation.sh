#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

sudo cloud-init clean --logs --seed
sudo rm -f /etc/ssh/ssh_host_*
sudo rm -rf /var/lib/dhcp/* /var/lib/systemd/network /var/lib/NetworkManager/*.lease*
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
echo "==> Done"
