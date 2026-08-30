variable "qemu_ubuntu_slim_iso_url" {
  type        = string
  description = "URL or local path to the Ubuntu 24.04 Server installation ISO used for ubuntu-slim"
}

variable "qemu_ubuntu_slim_iso_checksum" {
  type        = string
  default     = "none"
  description = "Checksum for qemu_ubuntu_slim_iso_url (for example: sha256:<value>)"
}

variable "qemu_accelerator" {
  type        = string
  default     = "kvm"
  description = "QEMU accelerator to use (kvm, hvf, tcg, none)"
}

variable "qemu_cpu_type" {
  type        = string
  default     = "host"
  description = "QEMU CPU model for ubuntu-slim builds"
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

variable "ubuntu_slim_scripts_root" {
  type        = string
  default     = ""
  description = "Optional override for ubuntu-slim upstream scripts root"
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = "packer"
}
