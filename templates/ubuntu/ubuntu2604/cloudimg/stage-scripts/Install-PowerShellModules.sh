#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1
export HELPER_SCRIPTS=/imagegeneration/helpers
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/toolsets

echo "==> Running Install-PowerShellModules.ps1"
sudo -E pwsh -File /imagegeneration/toolsets/Install-PowerShellModules.ps1
echo "==> Running Install-PowerShellAzModules.ps1"
sudo -E pwsh -File /imagegeneration/toolsets/Install-PowerShellAzModules.ps1
echo "==> Done"
