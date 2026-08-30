packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu-slim" {
  vm_name        = "runner-image-qemu-ubuntu-slim"
  headless       = true
  accelerator    = var.qemu_accelerator
  machine_type   = "q35"
  qemuargs       = [["-cpu", var.qemu_cpu_type]]
  disk_interface = "virtio"
  net_device     = "virtio-net"

  iso_url      = var.qemu_ubuntu_slim_iso_url
  iso_checksum = var.qemu_ubuntu_slim_iso_checksum

  output_directory = "output-qemu-ubuntu-slim"
  format           = "qcow2"
  disk_size        = var.ubuntu_disk_size_gb * 1024

  cpus        = var.ubuntu_cpu_cores
  memory      = var.ubuntu_memory_mb
  ssh_timeout = "6h"

  http_directory = "http"

  boot_command = [
    "<esc><wait>e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<f10>"
  ]

  communicator = "ssh"
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
}

locals {
  ubuntu_slim_root       = var.ubuntu_slim_scripts_root != "" ? var.ubuntu_slim_scripts_root : "${path.root}/../../../../vendor/runner-images/images/ubuntu-slim"
  helper_script_folder   = "/imagegeneration/helpers"
  build_script_folder    = "/imagegeneration/build"
  installer_script_folder = "/imagegeneration/toolsets"
  image_version          = "dev"
  image_os               = "ubuntu24-slim"
  imagedata_name         = "ubuntu:24.04-slim"
}

build {
  sources = ["source.qemu.ubuntu-slim"]

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:prepare-image-generation] Prepare image generation workspace'"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "mkdir -p /imagegeneration",
      "chmod 777 /imagegeneration",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:upload-slim-assets] Upload ubuntu-slim scripts and assets'"]
  }

  provisioner "file" {
    destination = "${local.build_script_folder}"
    source      = "${local.ubuntu_slim_root}/scripts/build"
  }

  provisioner "file" {
    destination = "${local.helper_script_folder}"
    source      = "${local.ubuntu_slim_root}/scripts/helpers"
  }

  provisioner "file" {
    destination = "${local.installer_script_folder}"
    source      = "${local.ubuntu_slim_root}/toolsets"
  }

  provisioner "file" {
    source      = "${path.root}/../../../../scripts/github-api-curl-wrapper.sh"
    destination = "/tmp/github-api-curl-wrapper.sh"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-github-api-wrapper] Configure GitHub API rate-limit wrapper'"]
  }

  provisioner "shell" {
    environment_vars = [
      "GH_API_TOKEN=${var.github_api_token}",
      "GH_API_MIN_REMAINING=${var.github_api_min_remaining}",
      "GH_API_WAIT_BUFFER_SECONDS=${var.github_api_wait_buffer_seconds}",
    ]
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "install -m 0755 /tmp/github-api-curl-wrapper.sh /usr/local/bin/curl",
      "printf 'GITHUB_API_MIN_REMAINING=%s\\nGITHUB_API_WAIT_BUFFER_SECONDS=%s\\n' \"$GH_API_MIN_REMAINING\" \"$GH_API_WAIT_BUFFER_SECONDS\" > /etc/github-api-rate-limit.conf",
      "if [ -n \"$GH_API_TOKEN\" ]; then printf '%s' \"$GH_API_TOKEN\" > /etc/github-api-token; chmod 644 /etc/github-api-token; fi",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-slim-toolset] Install ubuntu-slim toolset'"]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${local.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}",
      "DEBIAN_FRONTEND=noninteractive",
      "IMAGE_VERSION=${local.image_version}",
      "IMAGE_OS=${local.image_os}",
      "IMAGEDATA_NAME=${local.imagedata_name}",
    ]
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "${local.ubuntu_slim_root}/scripts/build/configure-apt-sources.sh",
      "${local.ubuntu_slim_root}/scripts/build/configure-apt.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-apt-vital.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-ms-repos.sh",
      "${local.ubuntu_slim_root}/scripts/build/configure-image-data-file.sh",
      "${local.ubuntu_slim_root}/scripts/build/configure-environment.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-actions-cache.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-apt-common.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-azcopy.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-azure-cli.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-azure-devops-cli.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-bicep.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-aws-tools.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-git.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-git-lfs.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-github-cli.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-google-cloud-cli.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-nvm.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-nodejs.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-powershell.sh",
      "${local.ubuntu_slim_root}/scripts/build/configure-dpkg.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-yq.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-python.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-zstd.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-pipx-packages.sh",
      "${local.ubuntu_slim_root}/scripts/build/install-docker-cli.sh",
      "${local.ubuntu_slim_root}/scripts/build/configure-system.sh",
      "${local.ubuntu_slim_root}/scripts/helpers/cleanup.sh",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-actions-runner] Install GitHub Actions runner'"]
  }

  provisioner "shell" {
    inline = [
      "set -e",
      "sudo mkdir -p /opt/actions-runner",
      "sudo chown ${var.ssh_username}:${var.ssh_username} /opt/actions-runner",
      "cd /opt/actions-runner",
      "RUNNER_VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | grep '\"tag_name\"' | head -n1 | sed -E 's/.*\"v([^\"]+)\".*/\\1/')",
      "curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz",
      "tar xzf actions-runner-linux-x64.tar.gz && rm actions-runner-linux-x64.tar.gz",
      "sudo ./bin/installdependencies.sh",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:cleanup-template] Cleanup prior to template creation'"]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
    ]
  }
}
