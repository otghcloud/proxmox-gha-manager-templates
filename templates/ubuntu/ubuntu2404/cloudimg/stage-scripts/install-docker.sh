#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
SSH_USERNAME="$(id -un)"
export SSH_USERNAME
export HELPER_SCRIPTS=/imagegeneration/helpers
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/toolsets

echo "==> Running install-docker.sh"
sudo -E bash /imagegeneration/toolsets/install-docker.sh
sudo -E bash <<'GHA_STAGE_EOF'
set -euo pipefail
usermod -aG docker "$SSH_USERNAME"
GHA_STAGE_EOF
echo "==> Done"
