variable "qemu_windows2022_iso_url" {
  type        = string
  description = "Path or URL of the Windows Server 2022 installation ISO used by the QEMU builder"
}

variable "qemu_windows2022_iso_checksum" {
  type        = string
  default     = "none"
  description = "ISO checksum for the QEMU builder (set to none to skip checksum verification)"
}

variable "qemu_virtio_iso_path" {
  type        = string
  description = "Local path to the VirtIO drivers ISO attached to the QEMU build VM"
}

variable "qemu_accelerator" {
  type        = string
  default     = "kvm"
  description = "QEMU accelerator mode (for example kvm, hvf, whpx or tcg)"
}

variable "qemu_cpu_type" {
  type        = string
  default     = "host"
  description = "CPU model exposed to the QEMU guest"
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
