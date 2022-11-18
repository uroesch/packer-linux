# -----------------------------------------------------------------------------
# Variables 
# -----------------------------------------------------------------------------
variable "cpu" {
  type        = number
  default     = "2"
  description = "Number of CPUs to allocate for the build virtual machine."
}

variable "ram" {
  type        = number
  default     = "2048"
  description = "Number of MB to allocate for the build virtual machine."
}

variable "disk_size" {
  type        = number
  default     = "40000"
  description = "Size in MB of the OS root disk to be built."
  validation {
    condition     = can(var.disk_size >= 10000)
    error_message = "The 'disk_size' must be larget or equal to '10000'."
  }
}

variable "destination_dir" {
  type        = string
  default     = "artifacts"
  description = "Directory where to store built disk images."
}

variable "disk_path" {
  type        = string
  description = "Path to the disk device in linux e.g. '/dev/sda'."
  validation {
    condition     = can(regex("^/dev/", var.disk_path))
    error_message = "The 'disk_path' must start with '/dev/'."
  }
}

variable "headless" {
  type        = string
  default     = "true"
  description = "Show the console window during the build process."
}

variable "http_dir" {
  type        = string
  default     = "http"
  description = "Directory where to place the packer provided content."
}

variable "iso_checksum" {
  type        = string
  description = "The checksum of the ISO files must start."
  validation {
    condition     = can(regex("^(file:.*|(md5|sha(1|256|512)):(?i:[0-9a-f])+)", var.iso_checksum))
    error_message = "The 'iso_checksum' must be of format '<hash-type>:<base64-checksum>' or 'file:<path>'."
  }
}

variable "iso_base_dir" {
  type        = string
  default     = "iso"
  description = "Directory where the ISO files are located."
}

variable "iso_file" {
  type        = string
  description = "Base name of ISO file."
}

variable "iso_base_url" {
  type        = string
  description = "Download URL of ISO without 'var.iso_file'."
}

variable "name" {
  type        = string
  description = "Name of the OS to install e.g. 'centos' or 'ubuntu'."
}

variable "version" {
  type        = string
  description = "Version number of the OS to install."
}

variable "version_minor" {
  type        = string
  description = "Minor version number of the OS."
}

variable "repo_url" {
  type        = string
  description = "Red Hat Enterprise Linux URL for OS installation."
  default     = ""
}

variable "appstream_url" {
  type        = string
  default     = ""
  description = "Red Hat Enterprise Linux 8 and greater URL for AppStreams."
}

variable "root_password" {
  type        = string
  sensitive   = true
  description = "Root user password set during inital installation."
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  description = "SSH password used by provisioners."
}

variable "ssh_username" {
  type        = string
  description = "SSH user used by provisioners."
}

variable "target" {
  type        = string
  description = "Template to use for disk-layout and other domain specific options."
}

variable "vg_name" {
  type        = string
  default     = "vg_root"
  description = "LVM volume group name to use for the installation."
}

variable "code_name" {
  type        = string
  default     = ""
  description = "Code name of Debian or Ubuntu releases e.g. 'buster' or 'focal'."
}

variable "answer_file" {
  type        = string
  default     = "kickstart.cfg"
  description = "The name of the answer file to use for installation."
}

variable "volume_id" {
  type        = string
  default     = ""
  description = "The volume id of the iso file"
}

variable "firmware" {
  type        = string
  default     = "bios"
  description = "The boot method is either 'bios' (default) or 'efi'"
}

variable "accelerator" {
  type        = string
  default     = "kvm"
  description = "Acceleration type for qemu virtualization; default 'kvm'"
}

variable "bios_boot_command" {
  type        = list(string)
  description = "A list of commands to be executed during BIOS ISO boot."
  default     = [
    "<up><wait><tab><wait> ",
    "net.ifnames=0 ",
    "biosdevname=0 ",
    "text ",
    "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/%s",
    "<enter><wait>"
  ]
}

variable "firmware_path" {
  type        = object({
    bios = string
    efi  = string
  })
  description = "Path to firmware blob."
  # ["-bios", "/usr/share/qemu/OVMF.fd"] ]
  default     = {
    bios      = ""
    efi       = "/usr/share/qemu/OVMF.fd"
  }
}

variable "efi_boot_command" {
  type        = list(string)
  description = "A list of commands to be executed during EFI ISO boot."
  default     = [
    "c<enter><wait>",
    "linuxefi /images/pxeboot/vmlinuz ",
    "quiet ",
    "net.ifnames=0 ",
    "biosdevname=0 ",
    "text ",
    "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/%s ",
    "inst.stage2=hd:LABEL=%s ",
    "<enter><wait2>",
    "initrdefi /images/pxeboot/initrd.img",
    "<enter><wait2>",
    "boot<enter><wait>"
  ]
}

variable "qemuargs" {
  type        = list(list(string))
  description = "Default qemuargs for the build"
  default     = [ [ "-vga", "qxl" ] ]
 
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
locals {
  dist_name        = "${var.name}_${var.version}"
  full_name        = "${var.name}_${var.version}.${var.version_minor}"
  output_base      = "${var.destination_dir}/qemu"
  output_directory = "${local.output_base}/${local.dist_name}-${var.target}"
  config_file      = "${local.dist_name}/${var.answer_file}"
  iso_dir          = "${path.root}/../${var.iso_base_dir}/${local.dist_name}"
  volume_id        = replace(var.volume_id, " ", "\\x20")
  boot_command     = {
    "bios" = format(join("", var.bios_boot_command), local.config_file),
    "efi"  = format(join("", var.efi_boot_command),  local.config_file, local.volume_id)
  }
  iso_urls         = [
    "${local.iso_dir}/${var.iso_file}",
    "${var.iso_base_url}/${var.iso_file}"
  ]
}
