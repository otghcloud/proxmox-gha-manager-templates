#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPT_FOLDER=/imagegeneration/helpers
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/toolsets
export IMAGE_FOLDER=/imagegeneration

echo "==> Running configure-system.sh"
sudo -E bash /imagegeneration/toolsets/configure-system.sh
echo "==> Done"
