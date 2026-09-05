#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

echo "==> Running cleanup.sh"
sudo -E bash /imagegeneration/toolsets/cleanup.sh
echo "==> Done"
