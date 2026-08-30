packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "windows2022" {
  vm_name      = "runner-image-qemu-windows2022"
  headless     = true
  accelerator  = var.qemu_accelerator
  machine_type = "q35"
  qemuargs     = [["-cpu", var.qemu_cpu_type], ["-drive", "file=${var.qemu_virtio_iso_path},media=cdrom,index=4"]]

  iso_url      = var.qemu_windows2022_iso_url
  iso_checksum = var.qemu_windows2022_iso_checksum

  cd_files = ["unattend/autounattend.xml", "unattend/install-guest-tools.ps1"]
  cd_label = "AUTOUNATTEND"

  output_directory = "output-qemu-windows2022"
  format           = "qcow2"
  disk_interface   = "virtio"
  disk_size        = var.windows_disk_size_gb * 1024
  # Formatted as D: in unattend/autounattend.xml.tpl - upstream scripts expect a D: temp drive.
  disk_additional_size = ["${var.windows_temp_disk_size_gb * 1024}M"]

  cpus   = var.windows_cpu_cores
  memory = var.windows_memory_mb

  boot_wait = "5s"
  boot_command = [
    "<spacebar><wait5>",
    "<spacebar><wait5>",
    "<spacebar><wait5>",
    "<spacebar>",
  ]

  communicator     = "winrm"
  winrm_username   = var.winrm_username
  winrm_password   = var.winrm_password
  winrm_timeout    = "45m"
  winrm_use_ssl    = false
  winrm_insecure   = true
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer shutdown\""
}

locals {
  windows_root          = "${path.root}/../../../../vendor/runner-images/images/windows"
  image_folder          = "C:\\image" # Upstream scripts reference this, do not change!
  helper_script_folder  = "C:\\Program Files\\WindowsPowerShell\\Modules\\"
  temp_dir              = "D:\\temp"
  image_version         = "dev"
  image_os              = "windows2022"
  agent_tools_directory = "C:\\hostedtoolcache\\windows"
  imagedata_file        = "C:\\imagedata.json"
  install_user          = "installer"
}

build {
  sources = ["source.qemu.windows2022"]

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:create-image-and-temp-directories] Create image and temp directories'"]
  }

  provisioner "powershell" {
    inline = [
      "New-Item -Path ${local.image_folder} -ItemType Directory -Force",
      "New-Item -Path ${local.temp_dir} -ItemType Directory -Force",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:upload-upstream-assets-scripts-and-toolsets] Upload upstream assets, scripts and toolsets'"]
  }

  provisioner "file" {
    destination = "${local.image_folder}\\"
    sources = [
      "${local.windows_root}/assets",
      "${local.windows_root}/scripts",
      "${local.windows_root}/toolsets",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:rearrange-helper-modules-and-toolset-file] Rearrange helper modules and toolset file'"]
  }

  provisioner "powershell" {
    inline = [
      "Move-Item '${local.image_folder}\\assets\\post-gen' 'C:\\post-generation'",
      "Remove-Item -Recurse '${local.image_folder}\\assets'",
      # docs-gen only feeds Generate-SoftwareReport.ps1, which we don't run - drop it.
      "Remove-Item -Recurse '${local.image_folder}\\scripts\\docs-gen' -ErrorAction SilentlyContinue",
      "Move-Item '${local.image_folder}\\scripts\\helpers' '${local.helper_script_folder}\\ImageHelpers'",
      "New-Item -Type Directory -Path '${local.helper_script_folder}\\TestsHelpers\\'",
      "Move-Item '${local.image_folder}\\scripts\\tests\\Helpers.psm1' '${local.helper_script_folder}\\TestsHelpers\\TestsHelpers.psm1'",
      "Move-Item '${local.image_folder}\\scripts\\tests' '${local.image_folder}\\tests'",
      "Remove-Item -Recurse '${local.image_folder}\\scripts'",
      "Move-Item '${local.image_folder}\\toolsets\\toolset-2022.json' '${local.image_folder}\\toolset.json'",
      "Remove-Item -Recurse '${local.image_folder}\\toolsets'",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:create-installer-admin-account-and-enable-winrm-basic-auth] Create installer admin account and enable WinRM basic auth'"]
  }

  # Create a second local admin for elevated_user provisioners
  provisioner "windows-shell" {
    inline = [
      "net user ${local.install_user} ${var.install_password} /add /passwordchg:no /passwordreq:yes /active:yes /Y",
      "net localgroup Administrators ${local.install_user} /add",
      "winrm set winrm/config/service/auth @{Basic=\"true\"}",
      "winrm get winrm/config/service/auth",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:verify-installer-account-is-a-local-admin] Verify installer account is a local admin'"]
  }

  provisioner "powershell" {
    inline = ["if (-not ((net localgroup Administrators) -contains '${local.install_user}')) { exit 1 }"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:enable-driver-test-signing] Enable driver test signing'"]
  }

  provisioner "powershell" {
    elevated_password = var.install_password
    elevated_user     = local.install_user
    inline            = ["bcdedit.exe /set TESTSIGNING ON"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:base-image-config-defender-powershell-windows-features-chocolatey] Base image config: Defender, PowerShell, Windows features, Chocolatey'"]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${local.image_version}", "IMAGE_OS=${local.image_os}", "AGENT_TOOLSDIRECTORY=${local.agent_tools_directory}", "IMAGEDATA_FILE=${local.imagedata_file}", "IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    execution_policy = "unrestricted"
    scripts = [
      "${local.windows_root}/scripts/build/Configure-WindowsDefender.ps1",
      "${local.windows_root}/scripts/build/Configure-PowerShell.ps1",
      "${local.windows_root}/scripts/build/Install-PowerShellModules.ps1",
      "${local.windows_root}/scripts/build/Install-WindowsFeatures.ps1",
      "${local.windows_root}/scripts/build/Install-Chocolatey.ps1",
      "${local.windows_root}/scripts/build/Configure-BaseImage.ps1",
      "${local.windows_root}/scripts/build/Configure-ImageDataFile.ps1",
      "${local.windows_root}/scripts/build/Configure-SystemEnvironment.ps1",
      "${local.windows_root}/scripts/build/Configure-DotnetSecureChannel.ps1",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:reboot-waiting-for-the-containers-feature-to-finish-enabling] Reboot, waiting for the Containers feature to finish enabling'"]
  }

  provisioner "windows-restart" {
    check_registry        = true
    restart_check_command = "powershell -command \"& {while ( (Get-WindowsOptionalFeature -Online -FeatureName Containers -ErrorAction SilentlyContinue).State -ne 'Enabled' ) { Start-Sleep 30; Write-Output 'InProgress' }}\""
    restart_timeout       = "10m"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:disable-the-wlan-service] Disable the WLAN service'"]
  }

  provisioner "powershell" {
    inline = ["Set-Service -Name wlansvc -StartupType Manual", "if ($(Get-Service -Name wlansvc).Status -eq 'Running') { Stop-Service -Name wlansvc}"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-docker-compose-powershell-core-webpi-and-tortoisesvn] Install Docker, Compose, PowerShell Core, WebPI and TortoiseSVN'"]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts = [
      "${local.windows_root}/scripts/build/Install-Docker.ps1",
      "${local.windows_root}/scripts/build/Install-DockerWinCred.ps1",
      "${local.windows_root}/scripts/build/Install-DockerCompose.ps1",
      "${local.windows_root}/scripts/build/Install-PowershellCore.ps1",
      "${local.windows_root}/scripts/build/Install-WebPlatformInstaller.ps1",
      "${local.windows_root}/scripts/build/Install-TortoiseSvn.ps1",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:reboot-after-the-docker-install] Reboot after the Docker install'"]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-visual-studio-and-kubernetes-tools] Install Visual Studio and Kubernetes tools'"]
  }

  provisioner "powershell" {
    elevated_password = var.install_password
    elevated_user     = local.install_user
    environment_vars  = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts = [
      "${local.windows_root}/scripts/build/Install-VisualStudio.ps1",
      "${local.windows_root}/scripts/build/Install-KubernetesTools.ps1",
    ]
    valid_exit_codes = [0, 3010]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:reboot-after-visual-studio] Reboot after Visual Studio'"]
  }

  provisioner "windows-restart" {
    check_registry  = true
    restart_timeout = "10m"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-wix-wdk-vs-extensions-azure-cli-chocolatey-packages-java-kotli] Install WiX, WDK, VS extensions, Azure CLI, Chocolatey packages, Java, Kotlin, OpenSSL'"]
  }

  provisioner "powershell" {
    pause_before     = "2m0s"
    environment_vars = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts = [
      "${local.windows_root}/scripts/build/Install-Wix.ps1",
      "${local.windows_root}/scripts/build/Install-WDK.ps1",
      "${local.windows_root}/scripts/build/Install-VSExtensions.ps1",
      "${local.windows_root}/scripts/build/Install-AzureCli.ps1",
      "${local.windows_root}/scripts/build/Install-AzureDevOpsCli.ps1",
      "${local.windows_root}/scripts/build/Install-ChocolateyPackages.ps1",
      "${local.windows_root}/scripts/build/Install-JavaTools.ps1",
      "${local.windows_root}/scripts/build/Install-Kotlin.ps1",
      "${local.windows_root}/scripts/build/Install-OpenSSL.ps1",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-the-service-fabric-sdk] Install the Service Fabric SDK'"]
  }

  provisioner "powershell" {
    execution_policy = "remotesigned"
    environment_vars = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts          = ["${local.windows_root}/scripts/build/Install-ServiceFabricSDK.ps1"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:reboot-after-the-service-fabric-sdk] Reboot after the Service Fabric SDK'"]
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:uninstall-the-bundled-azure-powershell-msi] Uninstall the bundled Azure PowerShell MSI'"]
  }

  provisioner "windows-shell" {
    inline = ["wmic product where \"name like '%%microsoft azure powershell%%'\" call uninstall /nointeractive"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:install-the-main-runner-toolset] Install the main runner toolset'"]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts = [
      "${local.windows_root}/scripts/build/Install-ActionsCache.ps1",
      "${local.windows_root}/scripts/build/Install-Ruby.ps1",
      "${local.windows_root}/scripts/build/Install-PyPy.ps1",
      "${local.windows_root}/scripts/build/Install-Toolset.ps1",
      "${local.windows_root}/scripts/build/Configure-Toolset.ps1",
      "${local.windows_root}/scripts/build/Install-NodeJS.ps1",
      "${local.windows_root}/scripts/build/Install-AndroidSDK.ps1",
      "${local.windows_root}/scripts/build/Install-PowershellAzModules.ps1",
      "${local.windows_root}/scripts/build/Install-Pipx.ps1",
      "${local.windows_root}/scripts/build/Install-Git.ps1",
      "${local.windows_root}/scripts/build/Install-GitHub-CLI.ps1",
      "${local.windows_root}/scripts/build/Install-PHP.ps1",
      "${local.windows_root}/scripts/build/Install-Rust.ps1",
      "${local.windows_root}/scripts/build/Install-Sbt.ps1",
      "${local.windows_root}/scripts/build/Install-Chrome.ps1",
      "${local.windows_root}/scripts/build/Install-EdgeDriver.ps1",
      "${local.windows_root}/scripts/build/Install-Firefox.ps1",
      "${local.windows_root}/scripts/build/Install-Selenium.ps1",
      "${local.windows_root}/scripts/build/Install-IEWebDriver.ps1",
      "${local.windows_root}/scripts/build/Install-Apache.ps1",
      "${local.windows_root}/scripts/build/Install-Nginx.ps1",
      "${local.windows_root}/scripts/build/Install-Msys2.ps1",
      "${local.windows_root}/scripts/build/Install-WinAppDriver.ps1",
      "${local.windows_root}/scripts/build/Install-R.ps1",
      "${local.windows_root}/scripts/build/Install-AWSTools.ps1",
      "${local.windows_root}/scripts/build/Install-DACFx.ps1",
      "${local.windows_root}/scripts/build/Install-MysqlCli.ps1",
      "${local.windows_root}/scripts/build/Install-SQLPowerShellTools.ps1",
      "${local.windows_root}/scripts/build/Install-SQLOLEDBDriver.ps1",
      "${local.windows_root}/scripts/build/Install-DotnetSDK.ps1",
      "${local.windows_root}/scripts/build/Install-Mingw64.ps1",
      "${local.windows_root}/scripts/build/Install-Haskell.ps1",
      "${local.windows_root}/scripts/build/Install-Stack.ps1",
      "${local.windows_root}/scripts/build/Install-Miniconda.ps1",
      "${local.windows_root}/scripts/build/Install-AzureCosmosDbEmulator.ps1",
      "${local.windows_root}/scripts/build/Install-Mercurial.ps1",
      "${local.windows_root}/scripts/build/Install-Zstd.ps1",
      "${local.windows_root}/scripts/build/Install-NSIS.ps1",
      "${local.windows_root}/scripts/build/Install-Vcpkg.ps1",
      "${local.windows_root}/scripts/build/Install-PostgreSQL.ps1",
      "${local.windows_root}/scripts/build/Install-Bazel.ps1",
      "${local.windows_root}/scripts/build/Install-AliyunCli.ps1",
      "${local.windows_root}/scripts/build/Install-RootCA.ps1",
      "${local.windows_root}/scripts/build/Install-MongoDB.ps1",
      "${local.windows_root}/scripts/build/Install-CodeQLBundle.ps1",
      "${local.windows_root}/scripts/build/Configure-Diagnostics.ps1",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:windows-updates-shell-and-developer-mode-config-llvm] Windows Updates, shell and developer mode config, LLVM'"]
  }

  provisioner "powershell" {
    elevated_password = var.install_password
    elevated_user     = local.install_user
    environment_vars  = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts = [
      "${local.windows_root}/scripts/build/Install-WindowsUpdates.ps1",
      "${local.windows_root}/scripts/build/Configure-DynamicPort.ps1",
      "${local.windows_root}/scripts/build/Configure-GDIProcessHandleQuota.ps1",
      "${local.windows_root}/scripts/build/Configure-Shell.ps1",
      "${local.windows_root}/scripts/build/Configure-DeveloperMode.ps1",
      "${local.windows_root}/scripts/build/Install-LLVM.ps1",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:reboot-waiting-for-windows-update-servicing-to-complete] Reboot, waiting for Windows Update servicing to complete'"]
  }

  provisioner "windows-restart" {
    check_registry        = true
    restart_check_command = "powershell -command \"& {if ((-not (Get-Process TiWorker.exe -ErrorAction SilentlyContinue)) -and (-not [System.Environment]::HasShutdownStarted) ) { Write-Output 'Restart complete' }}\""
    restart_timeout       = "30m"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:post-reboot-windows-updates-and-cleanup] Post-reboot Windows Updates and cleanup'"]
  }

  provisioner "powershell" {
    pause_before     = "2m0s"
    environment_vars = ["IMAGE_FOLDER=${local.image_folder}", "TEMP_DIR=${local.temp_dir}"]
    scripts          = ["${local.windows_root}/scripts/build/Install-WindowsUpdatesAfterReboot.ps1", "${local.windows_root}/scripts/build/Invoke-Cleanup.ps1"]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:download-the-github-actions-runner-binary] Download the GitHub Actions runner binary'"]
  }

  # Install the GitHub Actions runner binary but don't register it
  provisioner "powershell" {
    inline = [
      "mkdir C:\\actions-runner",
      "cd C:\\actions-runner",
      "$runnerVersion = ((Invoke-RestMethod -Uri 'https://api.github.com/repos/actions/runner/releases/latest').tag_name).TrimStart('v')",
      "Invoke-WebRequest -Uri \"https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip\" -OutFile actions-runner.zip",
      "Expand-Archive -Path actions-runner.zip -DestinationPath . -Force",
      "Remove-Item actions-runner.zip",
    ]
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:native-images-system-and-user-config-post-build-validation] Native images, system and user config, post-build validation'"]
  }

  provisioner "powershell" {
    environment_vars = ["INSTALL_USER=${local.install_user}"]
    scripts = [
      "${local.windows_root}/scripts/build/Install-NativeImages.ps1",
      "${local.windows_root}/scripts/build/Configure-System.ps1",
      "${local.windows_root}/scripts/build/Configure-User.ps1",
      "${local.windows_root}/scripts/build/Post-Build-Validation.ps1",
    ]
    skip_clean = true
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:final-reboot-before-sysprep] Final reboot before sysprep'"]
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  provisioner "shell-local" {
    inline = ["echo '[image-builder:stage:sysprep-generalize-for-the-proxmox-template] Sysprep generalize for the Proxmox template'"]
  }

  # Cleanup prior to Proxmox template creation
  provisioner "powershell" {
    inline = [
      "if( Test-Path $env:SystemRoot\\System32\\Sysprep\\unattend.xml ){ rm $env:SystemRoot\\System32\\Sysprep\\unattend.xml -Force}",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /mode:vm /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10 } else { break } }",
    ]
  }
}

