#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export IMAGE_VERSION=dev
export IMAGE_OS=ubuntu26
export HELPER_SCRIPTS=/imagegeneration/helpers

echo "==> Running configure-environment.sh"
sudo -E bash /imagegeneration/toolsets/configure-environment.sh
echo "==> Done"
