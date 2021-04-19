#!/bin/sh
# Copyright (c) 2021 Eduardo Ramos (https://github.com/testillano/h1mock)

#############
# VARIABLES #
#############
APP_DIR="/app"
PROV_DIR="${APP_DIR}/provision"
SERVER_PORT=${1:-8000}
B64_PROVISION="$2"
GUARD_SLEEP=2

#############
# FUNCTIONS #
#############
# $1: provision file
build_mock() {
  echo "[$(date +'%H:%M:%S')] Building mock app from provision '$1' ..."
  cp mock.pre mock.py.tmp
  cat "$1" >> mock.py.tmp
  sed 's/@{SERVER_PORT}/'${SERVER_PORT}'/' mock.post >> mock.py.tmp
  mv mock.py.tmp mock.py
}

# $1: file to guard events for, during GUARD_SLEEP seconds
event_guard() {
  sleep "${GUARD_SLEEP}"
  echo "[$(date +'%H:%M:%S')] Removing event guard for '$1' ..."
  rm -f "${1}.processed"
}

# Monitoring provision files
monitor_provision() {
  inotifywait -m "${PROV_DIR}" --exclude .processed$ -e create -e modify -e attrib --format '%w%f %e %T' --timefmt '%H:%M:%S' |
    while read file event tm; do
      echo -n "[${tm}] "
      # Filter grouped events to avoid multiple calls to 'build_mock':
      [ -f "${file}.processed" ] && echo "Event '${event}' filtered (same notification group for '${file}')" && continue
      echo -n "Received event '${event}' for provision: ${file}"
      [ ! -f "${file}" ] && echo " -> cannot process directory: ignored" && continue
      echo

      build_mock "${file}"
      touch "${file}.processed"
      event_guard "${file}" &
    done
}

#############
# EXECUTION #
#############

cd "${APP_DIR}"

# Create initial provision
PROV_dflt="${PROV_DIR}/default"
mkdir -p "${PROV_DIR}"
if [ -n "${B64_PROVISION}" ]
then
  echo "${B64_PROVISION}" | base64 -d > "${PROV_dflt}"
else
  cat << EOF > "${PROV_dflt}"
def registerRules():
  app.register_error_handler(404, answer)

def answer(e):
  help='<a href="https://github.com/testillano/h1mock#how-it-works">help here</a>'
  return help, 404, {"Content-Type":"text/html"}
EOF
fi
build_mock "${PROV_dflt}"

# Monitor future provisions
monitor_provision &

# Start mock server
python3 mock.py
echo "INVALID PROVISION OR UNEXPECTED EXCEPTION"
echo "RESTORING DEPLOYMENT PROVISION"

