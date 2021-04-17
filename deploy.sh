#!/bin/bash

#############
# VARIABLES #
#############
SERVICE_PORT=${1:-8000}
NAMESPACE__dflt=${USER}-h1mock
NAMESPACE=${NAMESPACE:-${NAMESPACE__dflt}}

#############
# EXECUTION #
#############
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_DIR" ] && { echo "You must execute under a valid git repository !" ; exit 1 ; }

helm delete -n "${NAMESPACE}" h1mock &>/dev/null
kubectl create namespace "${NAMESPACE}" &>/dev/null

SETTERS="--set service.port=${SERVICE_PORT}"
helm install h1mock -n "${NAMESPACE}" ${SETTERS} "${REPO_DIR}/helm/h1mock"

