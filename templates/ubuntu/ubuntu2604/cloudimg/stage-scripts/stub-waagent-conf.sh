#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

sudo -E bash <<'GHA_STAGE_EOF'
set -euo pipefail
touch /etc/waagent.conf
grep -q ResourceDisk.Format /etc/waagent.conf || echo 'ResourceDisk.Format=n' >> /etc/waagent.conf
grep -q ResourceDisk.EnableSwap /etc/waagent.conf || echo 'ResourceDisk.EnableSwap=n' >> /etc/waagent.conf
grep -q ResourceDisk.SwapSizeMB /etc/waagent.conf || echo 'ResourceDisk.SwapSizeMB=0' >> /etc/waagent.conf
GHA_STAGE_EOF
echo "==> Done"
