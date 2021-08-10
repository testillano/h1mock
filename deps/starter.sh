#!/bin/sh
# Copyright (c) 2021 Eduardo Ramos (https://github.com/testillano/h1mock)

#############
# VARIABLES #
#############
APP_DIR="/app"
PROV_DIR="${APP_DIR}/provision"
PROV_CONFIG_DIR="/config"
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

# $1: flask file built; $2: behavior file; $3: server port; $4: flask debug mode (True|False)
build_py() {
  local app=$1
  local file=$2
  local port=$3
  local debugMode=$4

  log "Building '${app}' flask app from file '${file}' serving on port '${port}' ..."

  # Logging level:
  local werkzeugLogLevel=ERROR
  [ -n "${VERBOSE}" ] && werkzeugLogLevel=INFO

  cat flask.pre | sed 's/@{WERKZEUG_LOG_LEVEL}/'${werkzeugLogLevel}'/' > "${app}.tmp"
  cat "${file}" >> "${app}.tmp"
  cat flask.post | sed 's/@{SERVER_PORT}/'${port}'/' | sed 's/@{DEBUG_MODE}/'${debugMode}'/' >> "${app}.tmp"
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

      build_py "mock.py" "${file}" "${SERVER_PORT}" True
      touch "${file}.processed"
      event_guard "${file}" &
    done
}

#############
# EXECUTION #
#############

cd "${APP_DIR}"
mkdir -p "${PROV_DIR}"

# Copy configmap provisions to writable provision directory:
for provision in $(find "${PROV_CONFIG_DIR}" -type f 2>/dev/null); do cp "${provision}" "${PROV_DIR}"; done

# fall back to create default initial provision:
default="${PROV_DIR}"/initial

if [ ! -f "${default}" ]
then
  cat << EOF > "${default}"
def registerRules():
  app.register_error_handler(404, answer)

def answer(e):
  help='<a href="https://github.com/testillano/h1mock#how-it-works">help here for mock provisions</a>'
  return help, 404, {"Content-Type":"text/html"}
EOF
fi

build_py "mock.py" "${default}" "${SERVER_PORT}" True

# Monitor future provisions
monitor_provision &

# Start provision server
build_py "admin.py" "admin.mid" "${ADMIN_PORT}" False
python3 admin.py &

# Start mock server
python3 mock.py
echo "INVALID PROVISION OR UNEXPECTED EXCEPTION"
echo "Initial deployment provision will be restored after restart !"

