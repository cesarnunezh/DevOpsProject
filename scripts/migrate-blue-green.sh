#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage:
  bash scripts/migrate-blue-green.sh <dev|staging|prod> <frontend-service|products-api|orders-api> <image_uri> [--keep-old]

Examples:
  bash scripts/migrate-blue-green.sh dev frontend-service cesarnunezh/frontend-service:latest
  bash scripts/migrate-blue-green.sh prod products-api cesarnunezh/products-api:prod-42-git-abcdef0 --keep-old
EOF
  exit 1
}

print_sep() {
  echo "=========================================================================="
}

if [[ $# -lt 3 || $# -gt 4 ]]; then
  usage
fi

ENV_NAME="$1"
SERVICE_NAME="$2"
IMAGE_URI="$3"
KEEP_OLD=0

if [[ $# -eq 4 ]]; then
  if [[ "$4" == "--keep-old" ]]; then
    KEEP_OLD=1
  else
    usage
  fi
fi

case "${ENV_NAME}" in
  dev|staging|prod)
    ;;
  *)
    echo "unsupported environment: ${ENV_NAME}" >&2
    usage
    ;;
esac

case "${SERVICE_NAME}" in
  frontend-service)
    CONTAINER_NAME="frontend-service"
    NODEPORT_SERVICE="frontend-service-nodeport"
    ;;
  products-api)
    CONTAINER_NAME="products-api"
    NODEPORT_SERVICE="products-api-nodeport"
    ;;
  orders-api)
    CONTAINER_NAME="orders-api"
    NODEPORT_SERVICE="orders-api-nodeport"
    ;;
  *)
    echo "unsupported service: ${SERVICE_NAME}" >&2
    usage
    ;;
esac

NAMESPACE="devops-${ENV_NAME}"
TARGET_DEPLOYMENT=""

if [[ -n "${KUBE_CONTEXT:-}" ]]; then
  kubectl config use-context "${KUBE_CONTEXT}" >/dev/null
fi

desired_replicas() {
  case "${ENV_NAME}:${SERVICE_NAME}" in
    dev:frontend-service|dev:products-api|dev:orders-api)
      echo 1
      ;;
    staging:frontend-service)
      echo 1
      ;;
    staging:products-api|staging:orders-api)
      echo 2
      ;;
    prod:frontend-service|prod:products-api|prod:orders-api)
      echo 2
      ;;
    *)
      echo 1
      ;;
  esac
}

current_color() {
  kubectl get service "${SERVICE_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.selector.version}' 2>/dev/null || true
}

show_service_selectors() {
  kubectl get service "${SERVICE_NAME}" "${NODEPORT_SERVICE}" -n "${NAMESPACE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.spec.selector.version}{"\n"}{end}'
}

cleanup_failed_target() {
  if [[ -n "${TARGET_DEPLOYMENT}" ]]; then
    kubectl scale "deployment/${TARGET_DEPLOYMENT}" -n "${NAMESPACE}" --replicas=0 >/dev/null 2>&1 || true
  fi
}

if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  echo "namespace ${NAMESPACE} does not exist" >&2
  echo "run: bash scripts/k8s-deploy.sh ${ENV_NAME} --bootstrap" >&2
  exit 1
fi

if ! kubectl get deployment "${SERVICE_NAME}-blue" -n "${NAMESPACE}" >/dev/null 2>&1; then
  echo "blue-green deployments for ${SERVICE_NAME} are missing in ${NAMESPACE}" >&2
  echo "run: bash scripts/k8s-deploy.sh ${ENV_NAME} --bootstrap" >&2
  exit 1
fi

ACTIVE_COLOR="$(current_color)"
if [[ "${ACTIVE_COLOR}" != "blue" && "${ACTIVE_COLOR}" != "green" ]]; then
  ACTIVE_COLOR="green"
fi

if [[ "${ACTIVE_COLOR}" == "blue" ]]; then
  TARGET_COLOR="green"
  OLD_COLOR="blue"
else
  TARGET_COLOR="blue"
  OLD_COLOR="green"
fi

TARGET_DEPLOYMENT="${SERVICE_NAME}-${TARGET_COLOR}"
OLD_DEPLOYMENT="${SERVICE_NAME}-${OLD_COLOR}"
REPLICAS="$(desired_replicas)"

print_sep
echo "Blue-Green migration starting"
echo "Namespace: ${NAMESPACE}"
echo "Service: ${SERVICE_NAME}"
echo "Current active color: ${ACTIVE_COLOR}"
echo "Target color: ${TARGET_COLOR}"
echo "Image: ${IMAGE_URI}"
echo "Desired replicas for target color: ${REPLICAS}"
echo "Keep old color running: ${KEEP_OLD}"
echo

print_sep
echo "Current service selectors"
show_service_selectors
echo

print_sep
echo "Current deployment state"
kubectl get deploy "${SERVICE_NAME}-blue" "${SERVICE_NAME}-green" -n "${NAMESPACE}"
echo

print_sep
echo "Scaling target deployment ${TARGET_DEPLOYMENT} to ${REPLICAS} replica(s)"
kubectl scale "deployment/${TARGET_DEPLOYMENT}" -n "${NAMESPACE}" --replicas="${REPLICAS}"
echo

print_sep
echo "Updating target deployment image"
kubectl set image "deployment/${TARGET_DEPLOYMENT}" "${CONTAINER_NAME}=${IMAGE_URI}" -n "${NAMESPACE}"
echo

trap cleanup_failed_target ERR

print_sep
echo "Waiting for rollout on ${TARGET_DEPLOYMENT}"
kubectl rollout status "deployment/${TARGET_DEPLOYMENT}" -n "${NAMESPACE}" --timeout=180s
echo

print_sep
echo "Target pods before traffic switch"
kubectl get pods -n "${NAMESPACE}" -l "app=${SERVICE_NAME},version=${TARGET_COLOR}" -o wide
echo

print_sep
echo "Switching stable services to ${TARGET_COLOR}"
kubectl patch service "${SERVICE_NAME}" -n "${NAMESPACE}" --type merge \
  -p "{\"spec\":{\"selector\":{\"app\":\"${SERVICE_NAME}\",\"version\":\"${TARGET_COLOR}\"}}}"
kubectl patch service "${NODEPORT_SERVICE}" -n "${NAMESPACE}" --type merge \
  -p "{\"spec\":{\"selector\":{\"app\":\"${SERVICE_NAME}\",\"version\":\"${TARGET_COLOR}\"}}}"
echo

print_sep
echo "Service selectors after traffic switch"
show_service_selectors
echo

if [[ "${KEEP_OLD}" -eq 0 ]]; then
  print_sep
  echo "Scaling old deployment ${OLD_DEPLOYMENT} down to 0"
  kubectl scale "deployment/${OLD_DEPLOYMENT}" -n "${NAMESPACE}" --replicas=0
  echo
else
  print_sep
  echo "Keeping old deployment ${OLD_DEPLOYMENT} running for demo purposes"
  echo
fi

trap - ERR

print_sep
echo "Final deployment state"
kubectl get deploy "${SERVICE_NAME}-blue" "${SERVICE_NAME}-green" -n "${NAMESPACE}"
echo

print_sep
echo "Final pod state"
kubectl get pods -n "${NAMESPACE}" -l "app=${SERVICE_NAME}" -o wide
