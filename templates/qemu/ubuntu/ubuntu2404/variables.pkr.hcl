variable "qemu_ubuntu2404_iso_url" {
  type        = string
  description = "Path or URL of the Ubuntu 24.04 server ISO used by the QEMU builder"
}

variable "qemu_ubuntu2404_iso_checksum" {
  type        = string
  default     = "none"
  description = "ISO checksum for the QEMU builder (set to none to skip checksum verification)"
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

variable "ubuntu_cpu_cores" {
  type        = number
  default     = 6
  description = "vCPU cores assigned to the Ubuntu build VM"
}

variable "ubuntu_memory_mb" {
  type        = number
  default     = 8192
  description = "Memory in MB assigned to the Ubuntu build VM"
}

variable "ubuntu_disk_size_gb" {
  type        = number
  default     = 160
  description = "Ubuntu build VM disk size in GB"

  validation {
    condition     = var.ubuntu_disk_size_gb >= 100
    error_message = "Ubuntu disk size must be at least 100 GB."
  }
}

variable "ubuntu_cleanup_reboot_start_retry_timeout" {
  type        = string
  default     = "10m"
  description = "Packer start_retry_timeout used after the reboot before cleanup.sh runs"
}

variable "github_api_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Optional GitHub API token used by Ubuntu install scripts that query api.github.com"
}

variable "github_api_min_remaining" {
  type        = number
  default     = 10
  description = "Minimum GitHub API requests remaining before wrappers wait for reset"
}

variable "github_api_wait_buffer_seconds" {
  type        = number
  default     = 15
  description = "Extra seconds to wait after GitHub's reset time before resuming requests"
}

variable "ubuntu_scripts_root" {
  type        = string
  default     = ""
  description = "Optional override for the Ubuntu upstream scripts root (used by sanitized mode)"
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = "packer"
}
