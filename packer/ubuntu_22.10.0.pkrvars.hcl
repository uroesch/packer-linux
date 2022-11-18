# -----------------------------------------------------------------------------
# Ubuntu 20.04 Packer Variable File
# -----------------------------------------------------------------------------
firmware          = "efi"
destination_dir   = "artifacts"
disk_path         = "/dev/vda"
disk_size         = "71680"
headless          = "true"
http_dir          = "http"
iso_checksum      = "sha256:874452797430a94ca240c95d8503035aa145bd03ef7d84f9b23b78f3c5099aed"
iso_file          = "ubuntu-22.10-live-server-amd64.iso"
iso_base_url      = "https://releases.ubuntu.com/kinetic/"
name              = "ubuntu"
repo_url          = ""
root_password     = "F00bar123"
ssh_password      = "F00bar123"
ssh_username      = "ubuntu"
target            = "server"
version           = "22.10"
version_minor     = ""
vg_name           = "system"
code_name         = "kinetic"
answer_file       = ""
bios_boot_command = [
  "<enter><enter><f6><esc><wait>",
  "<bs><bs><bs><bs>",
  "autoinstall ",
  "net.ifnames=0 ",
  "biosdevname=0 ",
  "ip=dhcp ",
  "ipv6.disable=1 ",
  "ds=nocloud-net;",
  "s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/%s ",
  "--- <enter>"
]
efi_boot_command  = [
  "c<enter><wait>",
  "linuxefi /casper/vmlinuz ",
  "quiet ",
  "autoinstall ",
  "net.ifnames=0 ",
  "biosdevname=0 ",
  "ip=dhcp ",
  "ipv6.disable=1 ",
  "ds=nocloud-net\\;",
  "s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/%s ",
  "---- ",  
  "; inst.stage2=hd:LABEL=%s ",
  "<enter><wait2>",
  "initrdefi /casper/initrd<enter><wait3>",
  "boot<enter><wait>"
]
