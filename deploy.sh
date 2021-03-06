#!/bin/bash
# $@: optional helm install arguments

#############
# VARIABLES #
#############
NAMESPACE__dflt=${USER}-h1mock
NAMESPACE=${NAMESPACE:-${NAMESPACE__dflt}}

#############
# EXECUTION #
#############
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_DIR" ] && { echo "You must execute under a valid git repository !" ; exit 1 ; }

helm delete -n "${NAMESPACE}" h1mock &>/dev/null
kubectl create namespace "${NAMESPACE}" &>/dev/null

echo
echo "Installing h1mock ..."
echo
helm install h1mock -n "${NAMESPACE}" "${REPO_DIR}/helm/h1mock" --wait $@

