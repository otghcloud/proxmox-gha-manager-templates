#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

sudo -E bash <<'GHA_STAGE_EOF'
set -euo pipefail
mv /imagegeneration/post-gen /imagegeneration/post-generation
GHA_STAGE_EOF
echo "==> Done"
