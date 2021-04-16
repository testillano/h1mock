#!/bin/sh
# Copyright (c) 2021 Eduardo Ramos (https://github.com/testillano/h1mock)

#############
# VARIABLES #
#############
APP_DIR="/app"
PROV_DIR="${APP_DIR}/provision"
PROVISION="${PROV_DIR}/rules-and-functions"

#############
# FUNCTIONS #
#############
# $1: provision file
build_mock() {
  cp mock.pre mock.py.tmp
  cat "$1" >> mock.py.tmp
  cat mock.post >> mock.py.tmp
  mv mock.py.tmp mock.py
}

monitor_provision() {
  inotifywait -m "${PROV_DIR}" -e create -e modify |
    while read dir action file; do
      echo "File '${dir}/${file}' detected via '$action'"
      build_mock "${dir}/${file}"
    done
}

#############
# EXECUTION #
#############

cd "${APP_DIR}"

# Monitor provisions
mkdir -p ${PROV_DIR}
monitor_provision &
sleep 1

# Create default mock if missing provision
if [ ! -f "${PROVISION}" ] # default mock configuration
then
  cat << EOF > "${PROVISION}"
def registerRules():
  pass

EOF
fi
sleep 1

# Start mock server
python3 mock.py

