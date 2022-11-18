#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------
set -o errexit
set -o nounset
set -o pipefail

set -x
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Global
# -----------------------------------------------------------------------------
declare -r VERSION=0.5.0
declare -r SCRIPT=${0##*/}
declare -r BASE_DIR=$(readlink -f $(dirname ${0})/..)
declare -r IMAGES_DIR=${BASE_DIR}/images
declare -g IMAGE_PATH=${IMAGE_PATH:-}
declare -g FORMAT="${FORMAT:-}"
declare -a FORMATS=()
declare -g DIST_NAME=${DIST_NAME:-}
declare -g TARGET=${TARGET:-server}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
function usage() {
  local exit_code=${1:-1}
  cat << USAGE

  Usage:
    ${SCRIPT} -f <target-format> -n <image-name> -t <target>

  Options:
    -h | --help             This message
    -f | --format <format>  Convert qcow2 to other disk format.
                            Can be issued multiple times.
                            Supported formats are:
                            * vmdk (vmware)
                            * vhd  (azure, hyper-v)
                            * vhdx (azure, hyper-v)
                            * gcp  (google cloud platform)
    -n | --name <name>      Name of the image e.g. ubuntu-20.04
    -p | --path <sourceimg> Path to the source image.
    -t | --target <target>  Target suffice e.g. server

USAGE
  exit ${exit_code}
}

function parse_options() {
  while (( ${#} > 0 )); do
    case ${1} in
    -t|--target) shift; TARGET=${1};;
    -n|--name)   shift; DIST_NAME=${1};;
    -f|--format) shift; FORMATS+=( "${1}" );;
    -p|--path)   shift; IMAGE_PATH="${1}";;
    -h|--help)   usage 0;;
    esac
    shift
  done
}

function evaluate_options() {
  # convert the format to an array for
  FORMATS+=( ${FORMAT} )
}

function image_type() {
  local path=${1}; shift;
  [[ -f ${path} ]] || echo "unknown"
  case $(file ${path}) in
  *QCOW2*)   echo qcow2;;
  *DOS/MBR*) echo raw;;
  *)         echo "unknown";;
  esac
}


function image_out() {
  local extension=${1} shift;
  echo "${IMAGES_DIR}/${DIST_NAME}-${TARGET}.${extension}"
}

function find_image() {
  local dist_name=${1}; shift;
  if [[ -n ${IMAGE_PATH} && -f ${IMAGE_PATH} ]]; then
    echo ${IMAGE_PATH}
    return
  fi
  find ${IMAGES_DIR} -name "${dist_name}-${TARGET}.qcow2"
}

function to_raw_image() {
  local img_in="${1}"; shift;
  local img_raw="${1:-${img_in%.*}.raw}"
  qemu-img convert -f qcow2 -O raw "${img_in}" "${img_raw}"
}

function disk_size() {
  local image=${1}; shift;
  qemu-img info -f raw --output json "${image}" | jq '."virtual-size"'
}

function calc_size() {
  local image=${1}; shift;
  local mb=$(( 1024 * 1024 ))
  local size=$(disk_size "${image}")
  local rounded_size=$(( (${size}/${mb} + 1) * ${mb} ))
  if (( $((${size} % ${mb} )) == 0 )); then
    echo ${size}
  else
   echo ${rounded_size}
  fi
}

function align_image() {
  local raw_image="${1}"; shift;
  local rounded_size="$(calc_size "${raw_image}")"
  qemu-img resize -f raw "${raw_image}" ${rounded_size}
}

function convert_disk() {
  local method=${1}; shift;
  local img_in=${1}; shift;
  local img_out=${1}; shift;
  local options=${1}; shift;
  qemu-img convert \
    -f $(image_type ${img_in}) \
    ${options:+-o ${options}} \
    -O ${method} \
    "${img_in}" \
    "${img_out}"
}

function to_vhd() {
  local dist_name=${1}; shift;
  local img_in=$(find_image ${dist_name})
  local img_raw="${img_in%.*}.raw"
  local img_out="$(image_out vhd)"
  to_raw_image "${img_in}" "${img_raw}"
  align_image "${img_raw}"
  convert_disk vpc "${img_raw}" "${img_out}" subformat=fixed,force_size
  touch --reference "${img_in}" "${img_out}"
}

function to_vhdx() {
  local dist_name=${1}; shift;
  local img_in=$(find_image ${dist_name})
  local img_out="$(image_out vhdx)"
  convert_disk vhdx "${img_in}" "${img_out}" subformat=dynamic
}

function to_vmdk() {
  local dist_name=${1}; shift;
  local img_in=$(find_image ${dist_name})
  local img_out="$(image_out vmdk)"
  convert_disk vmdk "${img_in}" "${img_out}" \
    adapter_type=lsilogic,subformat=streamOptimized,compat6
  touch --reference "${img_in}" "${img_out}"
}

function to_gcp() {
  local dist_name=${1}; shift;
  local img_in=$(find_image ${dist_name})
  local img_raw="${img_in%.*}.raw"
  local img_out="$(image_out tar.gz)"
  to_raw_image "${img_in}" "${img_raw}"
  align_image "${img_raw}"
  tar \
    --format=oldgnu \
    --sparse \
    --directory="${IMAGES_DIR}" \
    --transform="s|${img_raw##*/}|disk.raw|" \
    -czf "${img_out}" \
    "${img_raw##*/}"
  touch --reference "${img_in}" "${img_out}"
}

function convert_image() {
  for format in "${FORMATS[@]}"; do
    case ${format} in
    vmdk) to_vmdk "${DIST_NAME}";;
    vhd)  to_vhd  "${DIST_NAME}";;
    vhdx) to_vhdx "${DIST_NAME}";;
    gcp)  to_gcp "${DIST_NAME}";;
    *)    echo "Unknown disk format '${format}'"; usage 1;;
    esac
  done
}

function cleanup() {
  find ${IMAGES_DIR} -name "${DIST_NAME}-${TARGET}.raw" -delete
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
parse_options "${@}"
evaluate_options
convert_image ${DIST_NAME}
