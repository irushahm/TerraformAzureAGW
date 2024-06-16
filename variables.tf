variable "host_os" {
  type    = string
  default = "linux"
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "irusha" # Ensure this starts with an alphanumeric character
}

variable "vm_count" {
  description = "No. VMs you required"
  type        = number
  default     = 2
}