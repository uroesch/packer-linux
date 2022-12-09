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
    name = "azure"
  }

  source "qemu.linux_stage2" {
    name = "hyper-v"
  }

  provisioner "ansible" {
    only            = ["qemu.base"]
    playbook_file   = "./provisioners/postinstall.yml"
    extra_arguments = ["--diff"]
    max_retries     = 30 # for opensuse
  }

  provisioner "ansible" {
    except        = ["qemu.base"]
    playbook_file = "./provisioners/postinstall.yml"
    override = {
      vmware = {
        extra_arguments = ["--diff", "--tags", "vmware"]
      }
      azure = {
        extra_arguments = ["--diff", "--tags", "azure"]
      }
      hyper-v = {
        extra_arguments = ["--diff", "--tags", "hyper-v"]
      }
    }
  }

  post-processor "shell-local" {
    only = ["qemu.base"]
    inline = [
      "source='${local.output_directory}/packer-linux_base_image'",
      "mv $source images/${local.full_name}-${var.target}-${var.firmware}.qcow2",
      "rm -rf ${local.output_directory}"
    ]
  }

  post-processor "shell-local" {
    only   = ["qemu.vmware"]
    script = "scripts/convert-diskimage.sh"
    environment_vars = [
      "FORMAT=vmdk",
      "DIST_NAME=${local.full_name}",
      "TARGET=${var.target}-${var.firmware}",
      "IMAGE_PATH=${local.output_directory}/packer-linux_stage2",
      "DEBUG=true"
    ]
  }

  post-processor "shell-local" {
    only   = ["qemu.azure"]
    script = "scripts/convert-diskimage.sh"
    environment_vars = [
      "FORMAT=vhd",
      "DIST_NAME=${local.full_name}",
      "TARGET=${var.target}-${var.firmware}",
      "IMAGE_PATH=${local.output_directory}/packer-linux_stage2",
      "DEBUG=true"
    ]
  }

  post-processor "shell-local" {
    only   = ["qemu.hyper-v"]
    script = "scripts/convert-diskimage.sh"
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
