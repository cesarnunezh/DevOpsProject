#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage:
  k8s-deploy.sh <dev|staging|prod> [--bootstrap]

normal mode:
  promote one service image without re-applying the full overlay

bootstrap mode:
  apply the full environment overlay once to create/update static resources
EOF
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

ENV_NAME="$1"
BOOTSTRAP_ONLY=0

if [[ $# -eq 2 ]]; then
  if [[ "$2" == "--bootstrap" ]]; then
    BOOTSTRAP_ONLY=1
  else
    usage
  fi
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY_DIR="${ROOT_DIR}/k8s/overlays/${ENV_NAME}"
NAMESPACE="devops-${ENV_NAME}"

if [[ ! -d "${OVERLAY_DIR}" ]]; then
  echo "overlay not found: ${OVERLAY_DIR}" >&2
  exit 1
fi

mkdir -p \
  "${ROOT_DIR}/k8s/storage/dev/postgres" \
  "${ROOT_DIR}/k8s/storage/staging/postgres" \
  "${ROOT_DIR}/k8s/storage/prod/postgres"

if [[ -n "${KUBE_CONTEXT:-}" ]]; then
  kubectl config use-context "${KUBE_CONTEXT}" >/dev/null
fi

bootstrap_environment() {
  kubectl apply -k "${OVERLAY_DIR}"
}

bootstrap_if_missing() {
  echo "environment ${NAMESPACE} is missing; bootstrapping ${ENV_NAME} before deploy" >&2
  bootstrap_environment
}

if [[ "${BOOTSTRAP_ONLY}" -eq 1 ]]; then
  bootstrap_environment
  exit 0
fi

IMAGE_URI="${IMAGE_URI:-}"
MUTABLE_TAG="${MUTABLE_TAG:-}"
if [[ -z "${IMAGE_URI}" ]]; then
  echo "IMAGE_URI must be set" >&2
  exit 1
fi

case "${IMAGE_URI}" in
  cesarnunezh/frontend-service:*)
    SERVICE_NAME="frontend-service"
    CONTAINER_NAME="frontend-service"
    NODEPORT_SERVICE="frontend-service-nodeport"
    ;;
  cesarnunezh/products-api:*)
    SERVICE_NAME="products-api"
    CONTAINER_NAME="products-api"
    NODEPORT_SERVICE="products-api-nodeport"
    ;;
  cesarnunezh/orders-api:*)
    SERVICE_NAME="orders-api"
    CONTAINER_NAME="orders-api"
    NODEPORT_SERVICE="orders-api-nodeport"
    ;;
  cesarnunezh/database-service:*)
    SERVICE_NAME="database-service"
    CONTAINER_NAME="database-service"
    NODEPORT_SERVICE=""
    ;;
  *)
    echo "unsupported IMAGE_URI: ${IMAGE_URI}" >&2
    exit 1
    ;;
esac

image_exists() {
  local image_uri="$1"

  if [[ "${SKIP_IMAGE_CHECK:-0}" == "1" ]]; then
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    docker manifest inspect "${image_uri}" >/dev/null 2>&1
    return $?
  fi

  return 0
}

resolve_image_uri() {
  local preferred_image="$1"
  local fallback_tag="$2"
  local image_repo="${preferred_image%:*}"

  if image_exists "${preferred_image}"; then
    echo "${preferred_image}"
    return 0
  fi

  if [[ -n "${fallback_tag}" ]]; then
    local fallback_image="${image_repo}:${fallback_tag}"
    if image_exists "${fallback_image}"; then
      echo "${fallback_image}"
      return 0
    fi
  fi

  return 1
}

ensure_environment_exists() {
  if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    bootstrap_if_missing
  fi

  if ! kubectl get deployment "${SERVICE_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1 \
    && ! kubectl get deployment "${SERVICE_NAME}-blue" -n "${NAMESPACE}" >/dev/null 2>&1; then
    bootstrap_if_missing
  fi

  if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    echo "namespace ${NAMESPACE} is still missing after bootstrap" >&2
    exit 1
  fi

  if ! kubectl get deployment "${SERVICE_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1 \
    && ! kubectl get deployment "${SERVICE_NAME}-blue" -n "${NAMESPACE}" >/dev/null 2>&1; then
    echo "environment resources for ${NAMESPACE} are still missing after bootstrap" >&2
    exit 1
  fi
}

desired_replicas() {
  local env_name="$1"
  local service_name="$2"

  case "${env_name}:${service_name}" in
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
  local service_name="$1"
  kubectl get service "${service_name}" -n "${NAMESPACE}" -o jsonpath='{.spec.selector.version}' 2>/dev/null || true
}

switch_services() {
  local service_name="$1"
  local target_color="$2"

  kubectl patch service "${service_name}" -n "${NAMESPACE}" --type merge \
    -p "{\"spec\":{\"selector\":{\"app\":\"${service_name}\",\"version\":\"${target_color}\"}}}" >/dev/null

  if [[ -n "${NODEPORT_SERVICE}" ]]; then
    kubectl patch service "${NODEPORT_SERVICE}" -n "${NAMESPACE}" --type merge \
      -p "{\"spec\":{\"selector\":{\"app\":\"${service_name}\",\"version\":\"${target_color}\"}}}" >/dev/null
  fi
}

cleanup_failed_target() {
  if [[ -n "${TARGET_DEPLOYMENT:-}" ]]; then
    kubectl scale "deployment/${TARGET_DEPLOYMENT}" -n "${NAMESPACE}" --replicas=0 >/dev/null 2>&1 || true
  fi
}

RESOLVED_IMAGE_URI="$(resolve_image_uri "${IMAGE_URI}" "${MUTABLE_TAG}" || true)"
if [[ -z "${RESOLVED_IMAGE_URI}" ]]; then
  echo "no reachable image found. tried immutable IMAGE_URI='${IMAGE_URI}' and mutable fallback tag='${MUTABLE_TAG}'" >&2
  exit 1
fi

ensure_environment_exists

ACTIVE_COLOR=""
if [[ "${SERVICE_NAME}" != "database-service" ]]; then
  ACTIVE_COLOR="$(current_color "${SERVICE_NAME}")"
fi

if [[ "${SERVICE_NAME}" == "database-service" ]]; then
  kubectl set image "deployment/${SERVICE_NAME}" "${CONTAINER_NAME}=${RESOLVED_IMAGE_URI}" -n "${NAMESPACE}"
  kubectl rollout status "deployment/${SERVICE_NAME}" -n "${NAMESPACE}" --timeout=180s
  exit 0
fi

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
REPLICAS="$(desired_replicas "${ENV_NAME}" "${SERVICE_NAME}")"

trap cleanup_failed_target ERR
kubectl scale "deployment/${TARGET_DEPLOYMENT}" -n "${NAMESPACE}" --replicas="${REPLICAS}" >/dev/null
kubectl set image "deployment/${TARGET_DEPLOYMENT}" "${CONTAINER_NAME}=${RESOLVED_IMAGE_URI}" -n "${NAMESPACE}"
kubectl rollout status "deployment/${TARGET_DEPLOYMENT}" -n "${NAMESPACE}" --timeout=180s
switch_services "${SERVICE_NAME}" "${TARGET_COLOR}"
kubectl scale "deployment/${OLD_DEPLOYMENT}" -n "${NAMESPACE}" --replicas=0 >/dev/null
trap - ERR
