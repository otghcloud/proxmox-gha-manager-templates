#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPTS=/imagegeneration/helpers
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/toolsets
export IMAGE_VERSION=dev
export IMAGE_OS=ubuntu24-slim
export IMAGEDATA_NAME=ubuntu:24.04-slim

echo "==> Running configure-image-data-file.sh"
sudo -E bash /imagegeneration/build/configure-image-data-file.sh
echo "==> Done"
