#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------
set -o errexit
set -o nounset
set -o pipefail

trap restart EXIT

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------
declare -r SCRIPT_PATH=$(cd $(dirname ${BASH_ARGV0}); pwd)
declare -r SCRIPT=${BASH_ARGV0##*/}
declare -r VERSION=0.7.0
declare -r AUTHOR="Urs Roesch"
declare -r LICENSE=MIT
declare -r SHORTNAME=$(hostname -s)
declare -i NOVNC_PORT=${NOVNC_PORT:-6080}
declare -g NOVNC_DEBUG=${NOVNC_DEBUG:-false}
declare -g NOVNC_WEBROOT=
declare -g NOVNC_LOOP=true
declare -r NOVNC_TIMEOUT=10
declare -r PACKER_VNC_START=5900
declare -r PACKER_VNC_END=6000

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
function usage() {
  local exit_code=${1:-1}
  cat <<USAGE

  Usage:
    ${SCRIPT} [options]

  Options:
    -h | --help         This message
    -d | --debug        Run in debug mode e.g. shell tracing.
    -S | --service      Run as a service.
    -w | --web-root     Path to the novnc webroot file on disk.
    -p | --port <port>  Specify the port to listen on
                        Default: ${NOVNC_PORT}
    -V | --version      Display version and exit

  Descriptions:
    A small script searching for the packer VNC port and establishing
    a novnc proxy to it. This allows monitoring and debuging the
    progress of a packer build when running from within a container.

USAGE
  NOVNC_LOOP=false
  exit ${exit_code}
}

function parse_options() {
  while (( ${#} > 0 )); do
    case "${1}" in
    -d|--debug)    NOVNC_DEBUG=true;;
    -p|--port)     shift; NOVNC_PORT=${1};;
    -S|--service)  NOVNC_LOOP=false;;
    -V|--version)  version;;
    -w|--web-root) shift; NOVNC_WEBROOT=${1};;
    -h|--help)     usage 0;;
    esac
    shift
  done
}

function validate_options() {
  [[ ${NOVNC_DEBUG} == true ]] && set -o xtrace || :
}

function version() {
  printf "%s v%s\nCopyright (c) %s\nLicense - %s\n" \
    "${SCRIPT}" "${VERSION}" "${AUTHOR}" "${LICENSE}"
  NOVNC_LOOP=false
  exit 0
}

function find_vnc_port() {
  ss -Hntl \
   "( src 127.0.0.1 or src [::1] )" and \
   "( sport >= ${PACKER_VNC_START} and sport <= ${PACKER_VNC_END} )" | \
   awk '{ print $4; exit }'
}

function wait_for_vnc() {
  local vnc_address=''
  while [[ -z ${vnc_address} ]]; do
    vnc_address=$(find_vnc_port)
    sleep 1
  done
  echo ${vnc_address}
}

function stop_proxy() {
  local pid=$(ps -ef | awk '/[n]ovnc_proxy/ { print $2 }')
  kill -INT ${pid} || :
}

function check_status() {
  local current_address=${1}; shift;
  while [[ ${current_address} == "$(find_vnc_port)" ]]; do
    sleep ${NOVNC_TIMEOUT};
  done
}

function start_proxy() {
  novnc_proxy \
    --listen ${NOVNC_PORT} \
    --vnc ${vnc_address} \
    ${NOVNC_WEBROOT:+--web ${NOVNC_WEBROOT}} | \
    sed -n -e "/${SHORTNAME}/ { s/${SHORTNAME}/localhost/g; p }"
}

function run_proxy() {
  local vnc_address=$(wait_for_vnc)
  local pid=''
  start_proxy &
  check_status ${vnc_address}
  stop_proxy
}

function restart() {
  local exit_code=$?
  [[ ${NOVNC_LOOP} == false ]] && exit ${exit_code}
  sleep ${NOVNC_TIMEOUT}
  export NOVNC_PORT NOVNC_DEBUG
  exec ${SCRIPT_PATH}/${SCRIPT}
}

function stop() {
  NOVNC_LOOP=true && exit 0
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
parse_options "${@}"
validate_options
run_proxy
