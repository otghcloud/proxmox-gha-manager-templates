#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

sudo -E bash <<'GHA_STAGE_EOF'
set -euo pipefail
mount -o remount,size=5G /tmp
GHA_STAGE_EOF
echo "==> Done"
