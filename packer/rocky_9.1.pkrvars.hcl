# -----------------------------------------------------------------------------
# Centos8 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/rocky_9/Rocky-9.1-x86_64-dvd.iso.sha256"
iso_file        = "Rocky-9.1-x86_64-dvd.iso"
iso_base_url    = "https://mirror.puzzle.ch/rockylinux/9.1/isos/x86_64"
name            = "rocky"
repo_url        = "https://mirror.puzzle.ch/rockylinux/9.1/BaseOS/x86_64/os/"
appstream_url   = "https://mirror.puzzle.ch/rockylinux/mirror/pub/rocky/9.1/AppStream/x86_64/os/"
ssh_username    = "root"
version         = "9"
version_minor   = "1"
qemuargs        = [ [ "-cpu", "Cooperlake-v1" ] ]
