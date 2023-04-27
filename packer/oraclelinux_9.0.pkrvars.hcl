# -----------------------------------------------------------------------------
# Oracle Linux 9.0 Packer Variable File
# -----------------------------------------------------------------------------
iso_checksum    = "file:iso/oraclelinux_9/OracleLinux-R9-U0-x86_64-dvd.iso.sha256"
iso_file        = "OracleLinux-R9-U0-x86_64-dvd.iso"
iso_base_url    = "https://yum.oracle.com/ISOS/OracleLinux/OL9/u0/x86_64"
name            = "oraclelinux"
repo_url        = "https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/x86_64/"
ssh_username    = "root"
version         = "9"
version_minor   = "0"
qemuargs        = [ [ "-cpu", "Cooperlake-v1" ] ]
