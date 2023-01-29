# -----------------------------------------------------------------------------
# Ubuntu 20.04 Packer Variable File
# -----------------------------------------------------------------------------
http_dir          = "http"
iso_checksum      = "file:iso/ubuntu_20.04/ubuntu-20.04-live-server-amd64.iso.sha256"
iso_file          = "ubuntu-20.04-live-server-amd64.iso"
iso_base_url      = "https://old-releases.ubuntu.com/20.04/"
name              = "ubuntu"
ssh_username      = "ubuntu"
version           = "20.04"
version_minor     = ""
code_name         = "focal"
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
