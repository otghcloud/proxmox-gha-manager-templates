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
  default     = "tpl-ubuntu-slim"
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

variable "pmx_ubuntu_slim_iso_file" {
  type        = string
  description = "Proxmox volume ID of the Ubuntu 24.04 Server installation ISO used for ubuntu-slim"
}

variable "pmx_cpu_type" {
  type        = string
  default     = "host"
  description = "QEMU CPU model for ubuntu-slim builds"
}

variable "ubuntu_cpu_cores" {
  type        = number
  default     = 2
  description = "vCPU cores assigned to the Ubuntu build VM"
}

variable "ubuntu_memory_mb" {
  type        = number
  default     = 4096
  description = "Memory in MB assigned to the Ubuntu build VM"
}

variable "ubuntu_disk_size_gb" {
  type        = number
  default     = 50
  description = "Ubuntu build VM disk size in GB"

  validation {
    condition     = var.ubuntu_disk_size_gb >= 50
    error_message = "Disk size must be at least 50 GB."
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
  default = "runner"
}
