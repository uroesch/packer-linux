# -----------------------------------------------------------------------------
# Ubuntu 22.04.1 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum      = "file:iso/ubuntu_22.04/ubuntu-22.04.1-live-server-amd64.iso.sha256"
iso_file          = "ubuntu-22.04.1-live-server-amd64.iso"
iso_base_url      = "https://old-releases.ubuntu.com/releases/22.04"
name              = "ubuntu"
ssh_username      = "ubuntu"
version           = "22.04"
version_minor     = "1"
code_name         = "jammy"
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
