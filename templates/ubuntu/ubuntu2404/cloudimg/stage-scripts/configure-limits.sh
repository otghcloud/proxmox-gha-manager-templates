#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

echo "==> Running configure-limits.sh"
sudo -E bash /imagegeneration/toolsets/configure-limits.sh
echo "==> Done"
