#!/bin/bash

#############
# VARIABLES #
#############

REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_DIR" ] && { echo "You must execute under a valid git repository !" ; exit 1 ; }

export NAMESPACE=${USER}-test-h1mock

#############
# FUNCTIONS #
#############
# $1: what; $2: value; $3: reference
assert()
{
  local what="$1"
  local value="$2"
  local ref="$3"

  if [ "${value}" != "${ref}" ]
  then
    echo "[${what}] Assert error: ${value} != ${ref}"
    echo
    echo "RESPONSE RECEIVED:"
    echo
    cat ${REPO_DIR}/.response
    echo
    exit 1
  fi

  echo "[${what}] ${value} -> OK"
  return 0
}

#############
# EXECUTION #
#############

# shellcheck disable=SC2164
cd "${REPO_DIR}"

trap "rm -f ${REPO_DIR}/.response" EXIT

echo
echo "Test 1) Deploy default and test arbitrary URI ..."
echo
"${REPO_DIR}"/deploy.sh >/dev/null
POD=$(kubectl get pods -n ${NAMESPACE} -l "app.kubernetes.io/name=h1mock,app.kubernetes.io/instance=h1mock" --no-headers | awk '{ if ($3 == "Running") print $1 }')
kubectl exec -it -n ${NAMESPACE} ${POD} -- sh -c "curl -XGET -v http://0.0.0.0:8000/any/path/" > ${REPO_DIR}/.response

filterStatusCode=$(grep -o "404 NOT FOUND" ${REPO_DIR}/.response)
assert StatusCode "${filterStatusCode}" "404 NOT FOUND"

response=$(tail -n -1 ${REPO_DIR}/.response)
assert "HTML Response" "${response}" '<a href="https://github.com/testillano/h1mock#how-it-works">help here</a>'


echo
echo "Test 2) Provision 'foo bar' rules-and-functions file and test foo bar URI ..."
echo
kubectl cp -n ${NAMESPACE} ${REPO_DIR}/examples/rules-and-functions ${POD}:/app/provision
sleep 1
kubectl exec -it -n ${NAMESPACE} ${POD} -- sh -c "curl -XGET -v http://0.0.0.0:8000/app/v1/foo/bar" > ${REPO_DIR}/.response

filterStatusCode=$(grep -o "200 OK" ${REPO_DIR}/.response)
assert StatusCode "${filterStatusCode}" "200 OK"

kubectl exec -it -n ${NAMESPACE} ${POD} -- sh -c "curl -XGET http://0.0.0.0:8000/app/v1/foo/bar" > ${REPO_DIR}/.response

response=$(cat ${REPO_DIR}/.response | jq --compact-output .)
assert "Json Response" "${response}" '{"resultCode":0,"resultData":"answering a get"}'

