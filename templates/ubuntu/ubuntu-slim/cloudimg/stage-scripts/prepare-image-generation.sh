#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

echo "==> Configuring apt to never wait for interactive confirmation"
printf 'APT::Get::Assume-Yes "true";\nAPT::Get::allow-downgrades "true";\n' | sudo tee /etc/apt/apt.conf.d/90gha-noninteractive >/dev/null
printf 'Dpkg::Options {\n   "--force-confdef";\n   "--force-confold";\n}\n' | sudo tee /etc/apt/apt.conf.d/90gha-dpkg-options >/dev/null

echo "==> Stopping needrestart from restarting services underneath the build"
sudo mkdir -p /etc/needrestart/conf.d
# shellcheck disable=SC2016  # $nrconf is needrestart's own Perl config, not a shell variable.
printf '$nrconf{restart} = "l";\n$nrconf{kernelhints} = -1;\n$nrconf{ucodehints} = 0;\n' | sudo tee /etc/needrestart/conf.d/90gha.conf >/dev/null

echo "==> Deriving the DHCP identity from the MAC address"
sudo mkdir -p /etc/systemd/networkd.conf.d
# netplan defaults to a DUID derived from /etc/machine-id. Every clone of this template asks
# for a lease with that same DUID, so the DHCP server hands them all the same address no
# matter that Proxmox gave each one a unique MAC. link-layer keys the DUID on the MAC instead.
printf '[DHCPv4]\nDUIDType=link-layer\n\n[DHCPv6]\nDUIDType=link-layer\n' | sudo tee /etc/systemd/networkd.conf.d/99-gha-dhcp-identity.conf >/dev/null

sudo -E bash <<'GHA_STAGE_EOF'
set -euo pipefail
mkdir -p /imagegeneration
chmod 777 /imagegeneration
GHA_STAGE_EOF
sudo mkdir -p /imagegeneration/helpers /imagegeneration/build /imagegeneration/toolsets
echo "==> Done"
