# -----------------------------------------------------------------------------
# Centos8 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/almalinux_9/AlmaLinux-9.1-x86_64-dvd.iso.sha256"
iso_file        = "AlmaLinux-9.1-x86_64-dvd.iso"
iso_base_url    = "https://mirror.init7.net/almalinux/9.1/isos/x86_64"
name            = "almalinux"
repo_url        = "https://mirror.init7.net/almalinux/9.1/BaseOS/x86_64/os/"
appstream_url   = "https://mirror.init7.net/almalinux/9.1/AppStream/x86_64/os/"
ssh_username    = "root"
version         = "9"
version_minor   = "1"
qemuargs        = [ [ "-cpu", "Cooperlake-v1" ] ]
