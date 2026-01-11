#!/bin/bash

config_file=$1
buffer="$(cat ${config_file})"
cd $(dirname $0)

fail () {
  echo "$@" >&2
  exit 1
}

usage () {
  echo "$0 [ -p PACKAGE | -s SCRIPT ] BINARY" >&2
  exit $1
}

[ "${DISTRO}" ] || fail "No DISTRO specified"

function config() {
  echo "${buffer}"
}

function package_names() {
  config | jq '.[].name' | sort | xargs
}

function package_def() {
  config | jq '.[] | select(.name == "'$1'")'
}

function installer_def() {
  def="$(package_def $1)"
  distro_def="$(echo ${def} | jq '.'${DISTRO})"
  default_def="$(echo ${def} | jq '.default')"
  if [ "${distro_def}" != "null" ]; then
    echo "${distro_def}"
  else
    echo "${default_def}"
  fi
}

function get_field() {
  # get_field definition package_name name default
  value="$(eval $1 $2 | jq '.'$3)"
  [ "${value}" = "null" ] && value="$4"
  echo ${value}
}

function package_name() {
  get_field installer_def $1 package ""
}

function script_name() {
  get_field installer_def $1 script ""
}

function check_finish() {
  get_field installer_def $1 check_finish true
}

function check_which() {
  get_field installer_def $1 check_which true
}

for package in $(package_names); do
  args=""
  package_name="$(package_name ${package})"
  script_name="$(script_name ${package})"
  install_flag=$([ "${package_name}" ] && echo "-p ${package_name}" || echo "-s ${script_name}")
  check_finish_flag=$($(check_finish ${package}) && echo "" || echo " -F")
  check_which_flag=$($(check_which ${package}) && echo "" || echo " -W")
  cmd="./install.sh${check_which_flag}${check_finish_flag} ${install_flag} ${package}"
  echo ${cmd}
  eval ${cmd}
done
