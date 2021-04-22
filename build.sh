#!/bin/bash

#############
# VARIABLES #
#############
image_tag__dflt=latest
base_tag__dflt=latest

#############
# FUNCTIONS #
#############
# $1: variable by reference; $2: default value
_read() {
  local -n varname=$1
  local default=$2

  local s_default="<null>"
  [ -n "${default}" ] && s_default="${default}"
  echo "Input '$1' value [${s_default}]:"

  if [ -n "${varname}" ]
  then
    echo "${varname}"
  else
    read -r varname
    [ -z "${varname}" ] && varname=${default}
  fi
}

build_project_image() {
  echo
  echo "=== Build h1mock image ==="
  echo
  _read image_tag "${image_tag__dflt}"
  _read base_tag "${base_tag__dflt}"

  bargs="--build-arg base_tag=${base_tag}"

  set -x
  # shellcheck disable=SC2086
  docker build --rm ${bargs} -t testillano/h1mock:"${image_tag}" . || return 1
  set +x
}

build_ct_image() {
  echo
  echo "=== Build component test image ==="
  echo
  _read image_tag "${image_tag__dflt}"
  _read base_tag "${base_tag__dflt}"

  bargs="--build-arg base_tag=${base_tag}"

  set -x
  # shellcheck disable=SC2086
  docker build --rm ${bargs} -f ct/Dockerfile -t testillano/ct-h1mock:"${image_tag}" . || return 1 # context is '.' to access examples
  set +x
}

#############
# EXECUTION #
#############
# shellcheck disable=SC2164
cd "$(dirname "$0")"

build_project_image && build_ct_image

exit $?

