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
  default     = "tpl-ubuntu2404"
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

variable "pmx_iso_file" {
  type        = string
  description = "Proxmox volume ID of the Ubuntu 24.04 Server installation ISO"
}

variable "pmx_cpu_type" {
  type        = string
  default     = "host"
  description = "QEMU CPU model - kvm64 (the Proxmox default) lacks SSSE3, which Homebrew's Linux x86_64 build requires"
}

variable "build_cpu_cores" {
  type        = number
  default     = 6
  description = "vCPU cores assigned to the Ubuntu build VM"
}

variable "build_memory_mb" {
  type        = number
  default     = 8192
  description = "Memory in MB assigned to the Ubuntu build VM"
}

variable "build_disk_gb" {
  type        = number
  default     = 75
  description = "Ubuntu build VM disk size in GB"

  validation {
    condition     = var.build_disk_gb >= 75
    error_message = "Disk size must be at least 75 GB."
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

variable "runner_images_root" {
  type        = string
  default     = ""
  description = "Optional override for the Ubuntu upstream scripts root (used by sanitized mode)"
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Optional SSH public key to add to the runner user's authorized_keys"
}

variable "ssh_username" {
  type    = string
  default = "runner"
}
