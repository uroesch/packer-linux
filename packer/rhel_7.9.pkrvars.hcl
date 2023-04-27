# -----------------------------------------------------------------------------
# Centos7 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/rhel_7/rhel-server-7.9-x86_64-dvd.iso.sha256"
iso_file        = "rhel-server-7.9-x86_64-dvd.iso"
iso_base_url    = "behind paywall"
name            = "rhel"
repo_url        = "http://mirror.centos.org/centos-7/7/os/x86_64/"
ssh_username    = "root"
version         = "7"
version_minor   = "9"
