#!/bin/sh
# Copyright (c) 2021 Eduardo Ramos (https://github.com/testillano/h1mock)

#############
# VARIABLES #
#############
APP_DIR="/app"
PROV_DIR="${APP_DIR}/provision"
PROV_INITIAL_CONFIG_DIR="${APP_DIR}/provision/config"
SERVER_PORT=${1:-8000}
ADMIN_PORT=${2:-8074}
VERBOSE=$3
GUARD_SLEEP=2

#############
# FUNCTIONS #
#############
# $@: message
# Prepend: COMPLETE: skips timestamp and new line
log() {
  [ -z "${VERBOSE}" ] && return
  [ -n "${COMPLETE}" ] && echo -n $@ && return
  echo "[$(date +'%H:%M:%S')] $@"
}

# $1: flask file built; $2: behavior file; $3: server port
build_py() {
  local app=$1
  local file=$2
  local port=$3

  log "Building '${app}' flask app from file '${file}' serving on port '${port}' ..."

  # Logging level:
  local werkzeugLogLevel=ERROR
  [ -n "${VERBOSE}" ] && werkzeugLogLevel=INFO

  cat flask.pre | sed 's/@{WERKZEUG_LOG_LEVEL}/'${werkzeugLogLevel}'/' > "${app}.tmp"
  cat "${file}" >> "${app}.tmp"
  cat flask.post | sed 's/@{SERVER_PORT}/'${port}'/' >> "${app}.tmp"
  mv "${app}.tmp" "${app}"
}

# $1: file to guard events for, during GUARD_SLEEP seconds
event_guard() {
  sleep "${GUARD_SLEEP}"
  log "Removing event guard for '$1' ..."
  rm -f "${1}.processed"
}

# Monitoring provision files
monitor_provision() {
  inotifywait -m "${PROV_DIR}" --exclude .processed$ -e create -e modify -e attrib --format '%w%f %e %T' --timefmt '%H:%M:%S' |
    while read file event tm; do
      # Filter grouped events to avoid multiple calls to 'build_py':
      [ -f "${file}.processed" ] && log "Event '${event}' filtered at '${tm}' (same notification group for '${file}')" && continue
      log "Received event '${event}' for provision: ${file}"
      [ ! -f "${file}" ] && COMPLETE=yes log " -> cannot process directory: ignored" && continue

      build_py "mock.py" "${file}" "${SERVER_PORT}"
      touch "${file}.processed"
      event_guard "${file}" &
    done
}

#############
# EXECUTION #
#############

cd "${APP_DIR}"

# Symlink initial provision configuration
mkdir -p "${PROV_DIR}"
ln -s "${PROV_INITIAL_CONFIG_DIR}/initial" "${PROV_DIR}"
build_py "mock.py" "${PROV_DIR}/initial" "${SERVER_PORT}"

# Monitor future provisions
monitor_provision &

# Start provision server
build_py "admin.py" "admin.mid" "${ADMIN_PORT}"
python3 admin.py &

# Start mock server
python3 mock.py
echo "INVALID PROVISION OR UNEXPECTED EXCEPTION"
echo "Initial deployment provision will be restored after restart !"

