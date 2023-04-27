# -----------------------------------------------------------------------------
# Centos8 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/almalinux_8/AlmaLinux-8.7-x86_64-dvd.iso.sha256"
iso_file        = "AlmaLinux-8.7-x86_64-dvd.iso"
iso_base_url    = "https://mirror.init7.net/almalinux/8.7/isos/x86_64"
name            = "almalinux"
repo_url        = "https://mirror.init7.net/almalinux/8.7/BaseOS/x86_64/os/"
appstream_url   = "https://mirror.init7.net/almalinux/8.7/AppStream/x86_64/os/"
ssh_username    = "root"
version         = "8"
version_minor   = "7"
qemuargs        = [ [ "-cpu", "Cooperlake-v1" ] ]
