# -----------------------------------------------------------------------------
# Centos8 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/rhel_9/rhel-baseos-9.0-x86_64-dvd.iso.sha256"
iso_file        = "rhel-baseos-9.0-x86_64-dvd.iso"
iso_base_url    = "behind paywall"
name            = "rhel"
repo_url        = "https://mirror.puzzle.ch/rockylinux/9.0/BaseOS/x86_64/os/"
appstream_url   = "https://mirror.puzzle.ch/rockylinux/9.0/AppStream/x86_64/os/"
ssh_username    = "root"
version         = "9"
version_minor   = "0"
qemuargs        = [ [ "-cpu", "Cooperlake-v1" ] ]
