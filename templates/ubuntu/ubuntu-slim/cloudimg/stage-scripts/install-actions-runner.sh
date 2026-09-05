#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
SSH_USERNAME="$(id -un)"
export SSH_USERNAME

echo "==> Waiting for any in-progress apt/dpkg lock to clear"
for _ in $(seq 1 60); do
    if ! sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        break
    fi
    sleep 1
done
sudo mkdir -p /opt/actions-runner
sudo chown "$SSH_USERNAME":"$SSH_USERNAME" /opt/actions-runner
cd /opt/actions-runner
RUNNER_VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name"' | head -n1 | sed -E 's/.*"v([^"]+)".*/\1/')
curl -o actions-runner-linux-x64.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
tar xzf actions-runner-linux-x64.tar.gz && rm actions-runner-linux-x64.tar.gz
sudo ./bin/installdependencies.sh
echo "==> Done"
