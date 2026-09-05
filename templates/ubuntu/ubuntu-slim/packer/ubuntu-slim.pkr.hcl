packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu-slim" {
  proxmox_url              = var.pmx_url
  username                 = var.pmx_token_id
  token                    = var.pmx_token_secret
  insecure_skip_tls_verify = true

  node                 = var.pmx_node
  vm_id                = var.pmx_template_vmid
  vm_name              = var.pmx_template_name
  template_description = "GHA-MGR Image - ubuntu-slim"

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
  ubuntu_slim_root        = var.runner_images_root != "" ? var.runner_images_root : "${path.root}/../../../../vendor/runner-images/images/ubuntu-slim"
  helper_script_folder    = "/imagegeneration/helpers"
  build_script_folder     = "/imagegeneration/build"
  installer_script_folder = "/imagegeneration/toolsets"
  image_version           = "dev"
  image_os                = "ubuntu24-slim"
  imagedata_name          = "ubuntu:24.04-slim"
}
