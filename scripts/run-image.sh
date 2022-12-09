#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------
set -o errexit
set -o nounset
set -o pipefail

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------
declare -r ROOT_DIR=$(cd $(dirname ${0})/..; pwd)
declare -r IMAGES_DIR=${ROOT_DIR}/images

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
function start-vm() { 
  local -r disk="${disk}"; shift;
  local -r bios="${1:-}"; 

  # Use Cooperlake CPU for RHEL 9 images
  exec qemu-system-x86_64 \
    -smp cpus=2,sockets=2 \
    -drive file=${disk},if=virtio,cache=none,discard=unmap,format=qcow2 \
    -cpu Cooperlake-v1 \
    -device virtio-net,netdev=user.0 \
    -machine type=pc,accel=kvm \
    -netdev user,id=user.0,hostfwd=tcp::22222-:22 \
    -m 2048M \
    ${bios:+-bios "${bios}"} \
    &> /dev/null
}

function start-bios-vm() {
  local -r disk="${1}"; shift;
  start-vm "${disk}"
}

function start-efi-vm() {
  local -r disk="${1}"; shift;
  start-vm "${disk}" "/usr/share/qemu/OVMF.fd"
}

function run-image() {
  local -r disk="${1}"; shift;

  case "${disk}" in
  *efi.*) start-efi-vm "${disk}";;
  *bios.*) start-bios-vm "${disk}";;
  *)
  esac
}

function find-images() {
  find ${IMAGES_DIR} \
    -type f \
    -regex ".*/.*-\(efi\|bios\).qcow2" \
    -printf "%P\n" | \
    sort
}

function select-image() {
  PS3="Select an image to run: "
  select disk in $(find-images); do
    if [[ ${REPLY} =~ ^[0-9]+$ ]]; then
      run-image ${IMAGES_DIR}/${disk} &
      exit
    fi  
  done
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
select-image
