variable "pmx_url" {
  type = string
}

variable "pmx_token_id" {
  type = string
}

variable "pmx_token_secret" {
  type      = string
  sensitive = true
}

variable "pmx_node" {
  type = string
}

variable "pmx_template_vmid" {
  type        = number
  default     = null
  description = "Optional explicit Proxmox VMID for the generated template"
}

variable "pmx_template_name" {
  type        = string
  default     = "runner-image-pmx-windows2022"
  description = "Name given to the generated Proxmox VM template"
}

variable "pmx_network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Proxmox bridge the build VM attaches to"
}

variable "pmx_vlan_tag" {
  type        = number
  default     = 0
  description = "VLAN tag for the build VM; 0 leaves the interface untagged"
}

variable "pmx_iso_storage" {
  type = string
}

variable "pmx_vm_storage" {
  type = string
}

variable "pmx_windows2022_iso_file" {
  type        = string
  description = "Proxmox volume ID of the Windows Server 2022 installation ISO"
}

variable "pmx_cpu_type" {
  type        = string
  default     = "host,level=30" # works around a documented Hyper-V boot failure on recent Intel hosts (see qm(1))
  description = "QEMU CPU model"
}

variable "windows_cpu_cores" {
  type        = number
  default     = 6
  description = "vCPU cores assigned to the Windows build VM"
}

variable "windows_memory_mb" {
  type        = number
  default     = 8192
  description = "Memory in MB assigned to the Windows build VM"
}

variable "windows_disk_size_gb" {
  type        = number
  default     = 200
  description = "Windows build VM disk size in GB"

  validation {
    condition     = var.windows_disk_size_gb >= 150
    error_message = "Windows disk size must be at least 150 GB."
  }
}

variable "windows_temp_disk_size_gb" {
  type        = number
  default     = 50
  description = "Size in GB of the secondary disk formatted as D: for upstream scripts' TEMP_DIR (matches Azure's ephemeral disk upstream expects)"
}

variable "pmx_virtio_iso_file" {
  type        = string
  description = "Proxmox volume ID of the VirtIO drivers ISO"
}

variable "winrm_password" {
  type      = string
  sensitive = true
}

variable "winrm_username" {
  type    = string
  default = "runner"
}

variable "install_password" {
  type      = string
  sensitive = true
}
