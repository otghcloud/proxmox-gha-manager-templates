#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: gb
  network:
    network:
      version: 2
      ethernets:
        all-en:
          match:
            name: "en*"
          dhcp4: true
  ssh:
    install-server: true
    allow-pw: true
  identity:
    hostname: github-runner-ubuntu2404
    username: ${RUNNER_USERNAME}
    password: "${RUNNER_PASSWORD_HASH}"
  storage:
    layout:
      name: direct
  packages:
    - openssh-server
    - qemu-guest-agent
  late-commands:
    - echo '${RUNNER_USERNAME} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${RUNNER_USERNAME}
    - curtin in-target -- systemctl enable qemu-guest-agent
  user-data:
    disable_root: true
