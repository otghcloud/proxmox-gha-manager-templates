#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPTS=/imagegeneration/helpers

echo "==> Running post-build-validation.sh"
sudo -E bash /imagegeneration/toolsets/post-build-validation.sh
echo "==> Done"
