#!/bin/bash

#############
# VARIABLES #
#############

REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_DIR" ] && { echo "You must execute under a valid git repository !" ; exit 1 ; }

CHART_NAME=ct-h1mock
NAMESPACE="ns-${CHART_NAME}"
HELM_CHART="helm/${CHART_NAME}"
TAG=${TAG:-latest}

#############
# FUNCTIONS #
#############
usage() {
  cat << EOF

Usage: $0 [-h|--help] [ pytest extra options ]

       pytest options: extra options passed to 'pytest' executable.

       -h|--help:      this help

       Prepend variables:

       XTRA_HELM_SETS: additional setters for helm install execution.
       SKIP_HELM_DEPS: non-empty value skip helm dependencies update.
       TAG:            h1mock and ct-h1mock images tag for deployment
                       (latest by default).
       REUSE:          non-empty value reuses or updates (if new TAG
                       is provided) the possible existing deployment
                       (by default, a cleanup is done).
       NO_TEST:        non-empty value skips test stage (only deploys).

       Examples:

       XTRA_HELM_SETS="--set h1mock_verbosity.enabled=true $0
       REUSE=true $0 # reuses in case already deployed
       TAG=test1 $0
       $0 -k test_001 # pytest arguments
EOF
}

# $1: namespace; $2: optional prefix app filter
get_pod() {
  #local filter="-o=custom-columns=:.metadata.name --field-selector=status.phase=Running"
  # There is a bug in kubectl: field selector status.phase is Running also for teminating pods
  local filter=
  [ -n "$2" ] && filter+=" -l app.kubernetes.io/name=${2}"

  # shellcheck disable=SC2086
  kubectl --namespace="$1" get pod --no-headers ${filter} | awk '{ if ($3 == "Running") print $1 }'
  return $?
}

# $1: test pod; $2-@: pytest arguments
do_test() {
  local test_pod=$1
  shift
  # shellcheck disable=SC2068
  kubectl exec -it "${test_pod}" -c test -n "${NAMESPACE}" -- pytest $@
}

#############
# EXECUTION #
#############

# shellcheck disable=SC2164
cd "${REPO_DIR}"

# shellcheck disable=SC2166
[ "$1" = "-h" -o "$1" = "--help" ] && usage && exit 0

echo
echo "==============================="
echo "Component test procedure script"
echo "==============================="
echo
echo "(-h|--help for more information)"
echo
echo "Chart name:       ${CHART_NAME}"
echo "Namespace:        ${NAMESPACE}"
[ -n "${XTRA_HELM_SETS}" ] && echo "XTRA_HELM_SETS:   ${XTRA_HELM_SETS}"
[ -n "${REUSE}" ] && echo "REUSE:            selected"
echo "TAG:              ${TAG}"
[ -n "${NO_TEST}" ] && echo "NO_TEST:          selected"
[ $# -gt 0 ] && echo "Pytest arguments: $*"
echo

if [ -z "${REUSE}" ]
then
  echo -e "\nCleaning up ..."
  helm delete "${CHART_NAME}" -n "${NAMESPACE}" &>/dev/null
fi

# Check deployment existence:
list=$(helm list -q --deployed -n "${NAMESPACE}" | grep -w "${CHART_NAME}")
if [ -n "${list}" ] # reuse
then
  echo -e "\nWaiting for upgrade to tag '${TAG}' ..."
  kubectl set image "deployment/h1mock" -n "${NAMESPACE}" h1mock=testillano/h1mock:"${TAG}" &>/dev/null
  kubectl set image "deployment/ct-h1mock" -n "${NAMESPACE}" test=testillano/ct-h1mock:"${TAG}" &>/dev/null
  test_pod="$(get_pod "${NAMESPACE}" ct-h1mock)"
  h1mock_pod="$(get_pod "${NAMESPACE}" h1mock)"

  # shellcheck disable=SC2166
  [ -z "${test_pod}" -o -z "${h1mock_pod}" ] && echo "Missing target pods to upgrade" && exit 1

  # Check 10 times, during 1 minute (every 6 seconds):
  attempts=0
  until kubectl rollout status deployment/ct-h1mock -n "${NAMESPACE}" &>/dev/null || [ ${attempts} -eq 10 ]; do
    echo -n .
    sleep 6
    attempts=$((attempts + 1))
  done
else
  echo -e "\nPreparing to deploy chart '${CHART_NAME}' ..."
  # just in case, some failed deployment exists:
  helm delete "${CHART_NAME}" -n "${NAMESPACE}" &>/dev/null

  echo -e "\nUpdating helm chart dependencies ..."
  if [ -n "${SKIP_HELM_DEPS}" ]
  then
    echo "Skipped !"
  else
    helm dep update "${HELM_CHART}" &>/dev/null || { echo "Error !"; exit 1 ; }
  fi

  echo -e "\nDeploying chart ..."
  kubectl create namespace "${NAMESPACE}" &>/dev/null
  # shellcheck disable=SC2086
  helm install "${CHART_NAME}" "${HELM_CHART}" -n "${NAMESPACE}" --wait \
     --set test.image.tag="${TAG}" \
     --set h1mock_image.tag="${TAG}" \
     ${XTRA_HELM_SETS} || { echo "Error !"; exit 1 ; }
fi

[ -n "${NO_TEST}" ] && echo -e "\nTests skipped !" && exit 0

echo -e "\nExecuting tests ..."
test_pod="$(get_pod "${NAMESPACE}" ct-h1mock)"
[ -z "${test_pod}" ] && echo "Missing target pod for test" && exit 1

# shellcheck disable=SC2068
do_test "${test_pod}" $@

