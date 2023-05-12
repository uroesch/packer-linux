# -----------------------------------------------------------------------------
# RHEL 9.2 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/rhel_9/rhel-9.2-x86_64-dvd.iso.sha256"
iso_file        = "rhel-9.2-x86_64-dvd.iso"
iso_base_url    = "behind paywall"
name            = "rhel"
repo_url        = "https://mirror.init7.net/almalinux/9.2/BaseOS/x86_64/os/"
appstream_url   = "https://mirror.init7.net/almalinux/9.2/AppStream/x86_64/os/"
ssh_username    = "root"
version         = "9"
version_minor   = "2"
qemuargs        = [ [ "-cpu", "Cooperlake-v1" ] ]
