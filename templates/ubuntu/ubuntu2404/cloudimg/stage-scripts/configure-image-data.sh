#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPTS=/imagegeneration/helpers
export IMAGE_VERSION=dev
export IMAGEDATA_FILE=/imagegeneration/imagedata.json

echo "==> Running configure-image-data.sh"
sudo -E bash /imagegeneration/toolsets/configure-image-data.sh
echo "==> Done"
