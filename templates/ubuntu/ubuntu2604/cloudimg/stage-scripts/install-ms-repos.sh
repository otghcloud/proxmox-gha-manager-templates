#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPTS=/imagegeneration/helpers

echo "==> Running install-ms-repos.sh"
sudo -E bash /imagegeneration/toolsets/install-ms-repos.sh
echo "==> Running configure-apt-sources.sh"
sudo -E bash /imagegeneration/toolsets/configure-apt-sources.sh
echo "==> Running configure-apt.sh"
sudo -E bash /imagegeneration/toolsets/configure-apt.sh
echo "==> Done"
