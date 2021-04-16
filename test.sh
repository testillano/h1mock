#!/bin/bash
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_DIR" ] && { echo "You must execute under a valid git repository !" ; exit 1 ; }

export NAMESPACE=${USER}-h1mock
"${REPO_DIR}"/helm/install.sh
IP=$(kubectl get services -n "${NAMESPACE}" --no-headers | awk  '{ print $3 }')
POD=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=h1mock,app.kubernetes.io/instance=h1mock" -o jsonpath="{.items[0].metadata.name}")

cat << EOF

Quick guide & examples

1. Provision

 - kubectl cp -n "${NAMESPACE}" "${REPO_DIR}/example/rules-and-functions" "\${POD_NAME}:/app/provision"

2. Send request

 - minikube:
   curl -v -XGET http://${IP}:8000/app/v1/foo/bar

 - cluster:
   kubectl port-forward -n "${NAMESPACE}" "${POD}" 8000:8000 &
   curl -v -XGET http://localhost:8000/app/v1/foo/bar

 - remotely:
   kubectl exec -it -n "${NAMESPACE}" "\${POD_NAME}" -- sh -c "curl -v -XGET http://0.0.0.0:8000/app/v1/foo/bar"

