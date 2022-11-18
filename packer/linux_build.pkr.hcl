# -----------------------------------------------------------------------------
# Sources
# -----------------------------------------------------------------------------
source "qemu" "linux_base_image" {
  cpus                   = var.cpu
  memory                 = var.ram
  accelerator            = var.accelerator
  boot_command           = [ local.boot_command[var.firmware] ]
  boot_wait              = "3s"       # 5s for builds on nested-virt vmware
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
  net_device             = "virtio-net"
  output_directory       = "${var.destination_dir}/qemu/${local.dist_name}-${var.target}"
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password           = var.ssh_password
  ssh_username           = var.ssh_username
  ssh_timeout            = "30m"
  ssh_wait_timeout       = "60m"
  ssh_handshake_attempts = "500"      # required for ubuntu 20.04
  ssh_pty                = "false"    # required for ansible to work
  qemu_binary            = "/usr/bin/qemu-system-x86_64"
  qemuargs               = var.qemuargs
  firmware               = var.firmware_path[var.firmware]
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
  disk_interface         = "virtio"
  use_backing_file       = false
  format                 = "qcow2"
  # iso_checksum           = "file:./images/${local.dist_name}-${var.target}.qcow2.sha256"
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
  ssh_handshake_attempts = "500"      # required for ubuntu 20.04
  ssh_pty                = "false"    # required for ansible to work
  qemu_binary            = "/usr/bin/qemu-system-x86_64"
  qemuargs               = var.qemuargs
  firmware               = var.firmware_path[var.firmware]
}


# -----------------------------------------------------------------------------
# Builds
# -----------------------------------------------------------------------------
build {
  source "qemu.linux_base_image" {
    name = "base"
  }

  source "qemu.linux_stage2" {
    name = "vmware"
  }

  source "qemu.linux_stage2" {
    name         = "azure"
  }

  source "qemu.linux_stage2" {
    name         = "hyper-v"
  }

  provisioner "ansible" {
    only            = [ "qemu.base" ]
    playbook_file   = "./provisioners/postinstall.yml"
    extra_arguments = [ "--diff" ]
    max_retries     = 30 # for opensuse
  }

  provisioner "ansible" {
    only            = [ "qemu.vmware" ]
    playbook_file   = "./provisioners/postinstall.yml"
    extra_arguments = [ "--diff", "--tags", "vmware" ]
  }

  provisioner "ansible" {
    only            = [ "qemu.azure" ]
    playbook_file   = "./provisioners/postinstall.yml"
    extra_arguments = [ "--diff", "--tags", "azure" ]
  }

  provisioner "ansible" {
    only            = [ "qemu.hyper-v" ]
    playbook_file   = "./provisioners/postinstall.yml"
    extra_arguments = [ "--diff", "--tags", "hyper-v" ]
  }

  post-processor "shell-local" {
    only   = [ "qemu.base" ]
    inline = [
      "[ ! -d images ] && mkdir images",
      "source='${local.output_directory}/packer-linux_base_image'",
      "mv $source images/${local.full_name}-${var.target}-${var.firmware}.qcow2",
      "rm -rf ${local.output_directory}"
    ]
  }

  post-processor "shell-local" {
    only             = ["qemu.vmware"]
    script           = "scripts/convert-diskimage.sh"
    environment_vars = [
      "FORMAT=vmdk",
      "DIST_NAME=${local.full_name}",
      "TARGET=${var.target}-${var.firmware}",
      "IMAGE_PATH=${local.output_directory}/packer-linux_stage2",
      "DEBUG=true"
    ]
  }

  post-processor "shell-local" {
    only             = ["qemu.azure"]
    script           = "scripts/convert-diskimage.sh"
    environment_vars = [
      "FORMAT=vhd",
      "DIST_NAME=${local.full_name}",
      "TARGET=${var.target}-${var.firmware}",
      "IMAGE_PATH=${local.output_directory}/packer-linux_stage2",
      "DEBUG=true"
    ]
  }

  post-processor "shell-local" {
    only             = ["qemu.hyper-v"]
    script           = "scripts/convert-diskimage.sh"
    environment_vars = [
      "FORMAT=vhdx",
      "DIST_NAME=${local.full_name}",
      "TARGET=${var.target}-${var.firmware}",
      "IMAGE_PATH=${local.output_directory}/packer-linux_stage2",
      "DEBUG=true"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "rm -rf ${local.output_directory}"
    ]
  }
}
