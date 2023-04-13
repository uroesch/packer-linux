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
declare -r SCRIPT=${0##*/}
declare -r ROOT_DIR=$(cd $(dirname ${0})/..; pwd)
declare -r IMAGE_DIR=${ROOT_DIR}/images
declare -r ISO_DIR=${ROOT_DIR}/iso
declare -g SEARCH_DIR=${IMAGE_DIR}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
function usage() {
  local exit_code=${1:-1}
  cat << USAGE

  Usage:
    ${SCRIPT} [image|iso] [--help]

  Run an iso or a image in qemu for debugging or ansible testing.

USAGE
  exit ${exit_code}
}

function parse-options() {
  while (( ${#} > 0 )); do
    case "${1}" in
    iso)       SEARCH_DIR=${ISO_DIR};;
    image)     SEARCH_DIR=${IMAGE_DIR};;
    -h|--help) usage 0;;
    -*)        usage 1;;
    esac
    shift
  done
}

function start-vm() {
  local -r disk="${1}"; shift;
  local -r bios="${1:-}";

  # Use Cooperlake CPU for RHEL 9 images
  exec qemu-system-x86_64 \
    -smp cpus=2,sockets=2 \
    -drive $(disk-string "${disk}") \
    -cpu Cooperlake-v1 \
    -device virtio-net,netdev=user.0 \
    -machine type=pc,accel=kvm \
    -netdev user,id=user.0,hostfwd=tcp::22222-:22 \
    -m 2048M \
    -vga qxl \
    ${bios:+-bios "${bios}"} \
    &> /dev/null
}

function disk-string() {
  local disk="${1}"; shift
  case "${disk}" in
  *.iso)   echo file=${disk},media=cdrom;;
  *.qcow2) echo file=${disk},if=virtio,cache=none,discard=unmap,format=qcow2;;
  esac
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
  local -r firmware="${1}"; shift;
  local -r disk="${1}"; shift;

  case "${firmware}" in
  efi)  start-efi-vm "${disk}";;
  bios) start-bios-vm "${disk}";;
  esac
}

function select-firmware() {
  local disk="${1}}"; shift

  case "${disk}" in
  *efi*)  echo "efi"; return 0;;
  *bios*) echo "bios"; return 0;;
  esac

  PS3="Select a firmware type: "
  select firmware in efi bios; do
    if [[ ${REPLY} =~ ^[12]+$ ]]; then
      echo ${firmware}
      return 0
    fi
  done
}

function select-iso() {
  PS3="Select an image to run: "
  select iso in $(find-iso); do
    if [[ ${REPLY} =~ ^[0-9]+$ ]]; then
      run-iso ${firmware} ${ISO_DIR}/${iso} &
      exit
    fi
  done
}

function find-images() {
  find ${SEARCH_DIR} \
    -type f \
    \( -regex ".*/.*-\(efi\|bios\).qcow2" -o -name "*.iso" \) \
    -printf "%P\n" | \
    sort
}

function select-image() {
  PS3="Select an image to run: "
  select disk in $(find-images); do
    if [[ ${REPLY} =~ ^[0-9]+$ ]]; then
      firmware=$(select-firmware ${SEARCH_DIR}/${disk})
      run-image ${firmware} ${SEARCH_DIR}/${disk} &
      exit
    fi
  done
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
parse-options "${@}"
select-image
