# -----------------------------------------------------------------------------
# Sources
# -----------------------------------------------------------------------------
source "qemu" "linux_base_image" {
  cpus                   = var.cpu
  memory                 = var.ram
  accelerator            = var.accelerator
  boot_command           = [local.boot_command[var.firmware]]
  boot_wait              = var.boot_wait
  disk_cache             = "none"
  disk_compression       = true
  disk_discard           = "unmap"
  disk_interface         = "virtio"
  disk_size              = var.disk_size
  format                 = "qcow2"
  headless               = var.headless
  http_directory         = var.http_dir
  iso_checksum           = var.iso_checksum
  iso_urls               = local.iso_urls
  iso_target_path        = local.iso_target_path
  net_device             = "virtio-net"
  output_directory       = "${var.destination_dir}/qemu/${local.dist_name}-${var.target}"
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password           = var.ssh_password
  ssh_username           = var.ssh_username
  ssh_timeout            = "30m"
  ssh_wait_timeout       = var.ssh_wait_timeout
  ssh_handshake_attempts = "500"   # required for ubuntu 20.04
  ssh_pty                = "false" # required for ansible to work
  firmware               = var.firmware_path[var.firmware]
  qemu_binary            = "/usr/bin/qemu-system-x86_64"
  qemuargs               = var.qemuargs
}

source "qemu" "linux_stage2" {
  cpus                   = var.cpu
  memory                 = var.ram
  accelerator            = var.accelerator
  boot_wait              = "3s"
  disk_size              = var.disk_size
  disk_image             = true
  disk_cache             = "none"
  disk_compression       = true
  disk_discard           = "unmap"
  disk_interface         = "scsi"
  use_backing_file       = false
  format                 = "qcow2"
  iso_checksum           = "none"
  iso_url                = "images/${local.full_name}-${var.target}-${var.firmware}.qcow2"
  headless               = var.headless
  http_directory         = var.http_dir
  net_device             = "virtio-net"
  output_directory       = "${var.destination_dir}/qemu/${local.dist_name}-${var.target}"
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password           = var.ssh_password
  ssh_username           = var.ssh_username
  ssh_timeout            = "30m"
  ssh_wait_timeout       = "30m"
  ssh_handshake_attempts = "500"   # required for ubuntu 20.04
  ssh_pty                = "false" # required for ansible to work
  firmware               = var.firmware_path[var.firmware]
  qemu_binary            = "/usr/bin/qemu-system-x86_64"
  qemuargs               = concat(var.qemuargs, [
    ["-device", "virtio-scsi-pci,id=scsi" ],
    ["-device", "scsi-hd,drive=scsi-disk" ],
    ["-drive", "file=${var.destination_dir}/qemu/${local.dist_name}-${var.target}/packer-linux_stage2,id=scsi-disk,if=none,format=qcow2"]
  ])
}
