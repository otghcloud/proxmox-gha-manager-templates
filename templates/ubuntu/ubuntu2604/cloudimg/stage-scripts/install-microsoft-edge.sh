#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPTS=/imagegeneration/helpers
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/toolsets

echo "==> Running install-microsoft-edge.sh"
sudo -E bash /imagegeneration/toolsets/install-microsoft-edge.sh
echo "==> Done"
