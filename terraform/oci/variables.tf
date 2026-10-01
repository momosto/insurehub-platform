variable "region" {
  description = "OCI home region (Always Free resources must be in the home region)"
  type        = string
  default     = "af-johannesburg-1"
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "availability_domain_index" {
  description = "Try another AD if A1 capacity is unavailable (a known Always Free risk)"
  type        = number
  default     = 0
}

variable "ocpus" {
  description = "Always Free A1 allowance since June 2026: 2 OCPU in total"
  type        = number
  default     = 2
  validation {
    condition     = var.ocpus >= 1 && var.ocpus <= 2
    error_message = "Stay within the Always Free allowance (max 2 OCPU)."
  }
}

variable "memory_gb" {
  description = "Always Free A1 allowance since June 2026: 12 GB in total"
  type        = number
  default     = 12
  validation {
    condition     = var.memory_gb >= 6 && var.memory_gb <= 12
    error_message = "Stay within the Always Free allowance (max 12 GB)."
  }
}

variable "boot_volume_gb" {
  description = "Always Free block storage is 200 GB in total"
  type        = number
  default     = 100
}

variable "admin_cidr" {
  description = "The only address allowed to SSH (e.g. 203.0.113.10/32)"
  type        = string
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a specific CIDR, never 0.0.0.0/0."
  }
}

variable "admin_user" {
  type    = string
  default = "ops"
}

variable "ssh_public_key" {
  type = string
}

variable "k3s_version" {
  type    = string
  default = "v1.31.4+k3s1"
}

variable "cluster_hostname" {
  description = "Public name of the node, used for the k3s TLS SAN"
  type        = string
  default     = "k3s.insurehub.example.org"
}
