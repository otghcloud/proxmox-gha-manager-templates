packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu2404" {
  proxmox_url              = var.pmx_url
  username                 = var.pmx_token_id
  token                    = var.pmx_token_secret
  insecure_skip_tls_verify = true # set false once the Proxmox API has a trusted cert

  node                 = var.pmx_node
  vm_id                = var.pmx_template_vmid
  vm_name              = var.pmx_template_name
  template_description = "GHA-MGR Image - ubuntu-24.04"

  boot_iso {
    iso_file = var.pmx_iso_file
    unmount  = true
  }

  qemu_agent = true
  os         = "l26"
  bios       = "ovmf"
  machine    = "q35"

  efi_config {
    efi_storage_pool  = var.pmx_vm_storage
    efi_type          = "4m"
    pre_enrolled_keys = false
  }

  cpu_type        = var.pmx_cpu_type
  cores           = var.build_cpu_cores
  memory          = var.build_memory_mb
  scsi_controller = "virtio-scsi-single"

  disks {
    type         = "virtio"
    disk_size    = "${var.build_disk_gb}G"
    storage_pool = var.pmx_vm_storage
  }

  # Proxmox rejects `tag=0`, so the attribute has to be absent rather than zero when untagged.
  dynamic "network_adapters" {
    for_each = var.pmx_vlan_tag > 0 ? [var.pmx_vlan_tag] : []
    content {
      model    = "virtio"
      bridge   = var.pmx_network_bridge
      vlan_tag = network_adapters.value
    }
  }

  dynamic "network_adapters" {
    for_each = var.pmx_vlan_tag > 0 ? [] : [1]
    content {
      model  = "virtio"
      bridge = var.pmx_network_bridge
    }
  }

  http_directory = "http"

  boot_command = [
    "<esc><wait>e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<f10>"
  ]

  communicator = "ssh"
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "6h"
}

locals {
  ubuntu_root             = var.runner_images_root != "" ? var.runner_images_root : "${path.root}/../../../../vendor/runner-images/images/ubuntu"
  helper_script_folder    = "/imagegeneration/helpers"
  image_folder            = "/imagegeneration"
  installer_script_folder = "/imagegeneration/installers"
  imagedata_file          = "/imagegeneration/imagedata.json"
  image_version           = "dev"
  image_os                = "ubuntu24"
}

build {
  sources = ["source.proxmox-iso.ubuntu2404"]

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:create-the-image-generation-directory] Create the image generation directory'"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir ${local.image_folder}", "chmod 777 ${local.image_folder}"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:upload-helper-scripts] Upload helper scripts'"]
  }

  provisioner "file" {
    destination = "${local.helper_script_folder}"
    source      = "${local.ubuntu_root}/scripts/helpers"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:upload-github-api-curl-wrapper] Upload GitHub API curl wrapper'", "chmod +x ${path.root}/../../../../scripts/github-api-curl-wrapper.sh"]
  }

  provisioner "file" {
    source      = "${path.root}/../../../../scripts/github-api-curl-wrapper.sh"
    destination = "/tmp/github-api-curl-wrapper.sh"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-github-api-rate-limit-wrapper] Configure GitHub API rate-limit wrapper'", "chmod +x ${path.root}/../../../../scripts/github-rate-limit-preflight.sh"]
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
      "printf 'GITHUB_API_MIN_REMAINING=%s\nGITHUB_API_WAIT_BUFFER_SECONDS=%s\n' \"$GH_API_MIN_REMAINING\" \"$GH_API_WAIT_BUFFER_SECONDS\" > /etc/github-api-rate-limit.conf",
      "if [ -n \"$GH_API_TOKEN\" ]; then printf '%s' \"$GH_API_TOKEN\" > /etc/github-api-token; chmod 644 /etc/github-api-token; fi",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-the-apt-mock] Configure the apt mock'"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${local.ubuntu_root}/scripts/build/configure-apt-mock.sh"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:add-microsoft-repos-and-configure-apt-sources] Add Microsoft repos and configure apt sources'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "${local.ubuntu_root}/scripts/build/install-ms-repos.sh",
      "${local.ubuntu_root}/scripts/build/configure-apt-sources.sh",
      "${local.ubuntu_root}/scripts/build/configure-apt.sh",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-system-limits] Configure system limits'"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${local.ubuntu_root}/scripts/build/configure-limits.sh"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:upload-installer-scripts-post-gen-assets-tests-and-toolset] Upload installer scripts, post-gen assets, tests and toolset'"]
  }

  provisioner "file" {
    destination = "${local.installer_script_folder}"
    source      = "${local.ubuntu_root}/scripts/build"
  }

  provisioner "file" {
    destination = "${local.image_folder}"
    sources = [
      "${local.ubuntu_root}/assets/post-gen",
      "${local.ubuntu_root}/scripts/tests",
    ]
  }

  provisioner "file" {
    destination = "${local.installer_script_folder}/toolset.json"
    source      = "${local.ubuntu_root}/toolsets/toolset-2404.json"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:rename-post-gen-to-post-generation] Rename post-gen to post-generation'"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mv ${local.image_folder}/post-gen ${local.image_folder}/post-generation"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:write-the-image-data-file] Write the image data file'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "IMAGE_VERSION=${local.image_version}", "IMAGEDATA_FILE=${local.imagedata_file}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/configure-image-data.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:stub-waagent-conf-for-the-upstream-environment-script] Stub waagent.conf for the upstream environment script'"]
  }

  # configure-environment.sh expects an Azure-agent config file to tweak; our ISO has no
  # waagent installed, so stub one out with the keys it patches (no-op on a non-Azure host).
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "touch /etc/waagent.conf",
      "grep -q ResourceDisk.Format /etc/waagent.conf || echo 'ResourceDisk.Format=n' >> /etc/waagent.conf",
      "grep -q ResourceDisk.EnableSwap /etc/waagent.conf || echo 'ResourceDisk.EnableSwap=n' >> /etc/waagent.conf",
      "grep -q ResourceDisk.SwapSizeMB /etc/waagent.conf || echo 'ResourceDisk.SwapSizeMB=0' >> /etc/waagent.conf",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-the-image-environment] Configure the image environment'"]
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${local.image_version}", "IMAGE_OS=${local.image_os}", "HELPER_SCRIPTS=${local.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/configure-environment.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-vital-apt-packages] Install vital apt packages'"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/install-apt-vital.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-powershell] Install PowerShell'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/install-powershell.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-powershell-and-azure-modules] Install PowerShell and Azure modules'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/Install-PowerShellModules.ps1", "${local.ubuntu_root}/scripts/build/Install-PowerShellAzModules.ps1"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-the-main-runner-toolset] Install the main runner toolset'"]
  }

  # The bulk of GitHub's toolset from the upstream repository
  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}", "DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "${local.ubuntu_root}/scripts/build/install-actions-cache.sh",
      "${local.ubuntu_root}/scripts/build/install-apt-common.sh",
      "${local.ubuntu_root}/scripts/build/install-azcopy.sh",
      "${local.ubuntu_root}/scripts/build/install-azure-cli.sh",
      "${local.ubuntu_root}/scripts/build/install-azure-devops-cli.sh",
      "${local.ubuntu_root}/scripts/build/install-bicep.sh",
      "${local.ubuntu_root}/scripts/build/install-apache.sh",
      "${local.ubuntu_root}/scripts/build/install-aws-tools.sh",
      "${local.ubuntu_root}/scripts/build/install-clang.sh",
      "${local.ubuntu_root}/scripts/build/install-swift.sh",
      "${local.ubuntu_root}/scripts/build/install-cmake.sh",
      "${local.ubuntu_root}/scripts/build/install-codeql-bundle.sh",
      "${local.ubuntu_root}/scripts/build/install-awf.sh",
      "${local.ubuntu_root}/scripts/build/install-container-tools.sh",
      "${local.ubuntu_root}/scripts/build/install-dotnetcore-sdk.sh",
      "${local.ubuntu_root}/scripts/build/install-microsoft-edge.sh",
      "${local.ubuntu_root}/scripts/build/install-gcc-compilers.sh",
      "${local.ubuntu_root}/scripts/build/install-firefox.sh",
      "${local.ubuntu_root}/scripts/build/install-gfortran.sh",
      "${local.ubuntu_root}/scripts/build/install-git.sh",
      "${local.ubuntu_root}/scripts/build/install-git-lfs.sh",
      "${local.ubuntu_root}/scripts/build/install-github-cli.sh",
      "${local.ubuntu_root}/scripts/build/install-google-chrome.sh",
      "${local.ubuntu_root}/scripts/build/install-google-cloud-cli.sh",
      "${local.ubuntu_root}/scripts/build/install-haskell.sh",
      "${local.ubuntu_root}/scripts/build/install-java-tools.sh",
      "${local.ubuntu_root}/scripts/build/install-kubernetes-tools.sh",
      "${local.ubuntu_root}/scripts/build/install-miniconda.sh",
      "${local.ubuntu_root}/scripts/build/install-kotlin.sh",
      "${local.ubuntu_root}/scripts/build/install-mysql.sh",
      "${local.ubuntu_root}/scripts/build/install-nginx.sh",
      "${local.ubuntu_root}/scripts/build/install-nvm.sh",
      "${local.ubuntu_root}/scripts/build/install-nodejs.sh",
      "${local.ubuntu_root}/scripts/build/install-copilot-cli.sh",
      "${local.ubuntu_root}/scripts/build/install-bazel.sh",
      "${local.ubuntu_root}/scripts/build/install-php.sh",
      "${local.ubuntu_root}/scripts/build/install-postgresql.sh",
      "${local.ubuntu_root}/scripts/build/install-pulumi.sh",
      "${local.ubuntu_root}/scripts/build/install-ruby.sh",
      "${local.ubuntu_root}/scripts/build/install-rust.sh",
      "${local.ubuntu_root}/scripts/build/install-julia.sh",
      "${local.ubuntu_root}/scripts/build/install-selenium.sh",
      "${local.ubuntu_root}/scripts/build/install-packer.sh",
      "${local.ubuntu_root}/scripts/build/install-vcpkg.sh",
      "${local.ubuntu_root}/scripts/build/configure-dpkg.sh",
      "${local.ubuntu_root}/scripts/build/install-yq.sh",
      "${local.ubuntu_root}/scripts/build/install-android-sdk.sh",
      "${local.ubuntu_root}/scripts/build/install-pypy.sh",
      "${local.ubuntu_root}/scripts/build/install-python.sh",
      "${local.ubuntu_root}/scripts/build/install-zstd.sh",
      "${local.ubuntu_root}/scripts/build/install-ninja.sh",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-docker] Install Docker'"]
  }

  # Install Docker
  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/install-docker.sh"]
  }

  # Ensure the template SSH user can access /var/run/docker.sock.
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["usermod -aG docker ${var.ssh_username}"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-and-configure-the-hosted-toolcache] Install and configure the hosted toolcache'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/Install-Toolset.ps1", "${local.ubuntu_root}/scripts/build/Configure-Toolset.ps1"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-pipx-packages] Install pipx packages'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/install-pipx-packages.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-homebrew] Install Homebrew'"]
  }

  # Install homebrew as the unprivileged build user, not root
  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}", "DEBIAN_FRONTEND=noninteractive", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}"]
    execute_command  = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/install-homebrew.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-snap] Configure snap'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/configure-snap.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:record-the-installed-dpkg-package-list] Record the installed dpkg package list'"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${local.ubuntu_root}/scripts/build/list-dpkg.sh"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:reboot-the-vm] Reboot the VM'"]
  }

  provisioner "shell" {
    execute_command   = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    expect_disconnect = true
    inline            = ["echo 'Reboot VM'", "sudo reboot"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:cleanup-after-the-reboot] Cleanup after the reboot'"]
  }

  provisioner "shell" {
    execute_command     = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    pause_before        = "5m0s"
    scripts             = ["${local.ubuntu_root}/scripts/build/cleanup.sh"]
    start_retry_timeout = var.ubuntu_cleanup_reboot_start_retry_timeout
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:configure-the-system] Configure the system'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPT_FOLDER=${local.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${local.installer_script_folder}", "IMAGE_FOLDER=${local.image_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/configure-system.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:post-build-validation] Post-build validation'"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${local.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${local.ubuntu_root}/scripts/build/post-build-validation.sh"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:download-the-github-actions-runner-binary] Download the GitHub Actions runner binary'"]
  }

  # Install the GitHub Actions runner binary but don't register it
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
    inline = ["echo '[image-builder:stage:install-ssh-public-key] Install SSH public key'"]
  }

  provisioner "shell" {
    environment_vars = ["SSH_PUBLIC_KEY=${var.ssh_public_key}"]
    inline = [
      "set -e",
      "if [ -n \"$SSH_PUBLIC_KEY\" ]; then mkdir -p ~/.ssh && chmod 700 ~/.ssh && printf '%s\\n' \"$SSH_PUBLIC_KEY\" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys; fi",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:cleanup-prior-to-proxmox-template-creation] Cleanup prior to Proxmox template creation'"]
  }

  # Cleanup prior to Proxmox template creation
  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
    ]
  }
}
