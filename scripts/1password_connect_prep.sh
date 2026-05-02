#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-apply}"
CLUSTER_NAME="${CLUSTER_NAME:-armlab}"
CONNECT_SERVER_NAME="${CONNECT_SERVER_NAME:-${CLUSTER_NAME}_k3s}"
VAULT="${VAULT:-homelab}"
SECRET_NAMESPACE="${SECRET_NAMESPACE:-external-secrets}"
CONNECT_TOKEN_NAME="${CONNECT_TOKEN_NAME:-${CLUSTER_NAME}_external-secret-operator-token}"
CONNECT_CREDENTIALS_DOC_NAME="${CONNECT_CREDENTIALS_DOC_NAME:-${CONNECT_SERVER_NAME}-1password-credentials.json}"
CONNECT_TOKEN_REF="op://${VAULT}/${CONNECT_TOKEN_NAME}/password"

usage() {
  cat <<EOF
usage: $0 [apply|init|rotate-token]

apply: headless mode for cluster rebuilds; reads Connect bootstrap data from 1Password
init:  one-time setup; creates or refreshes the Connect server/token and stores or reuses the bootstrap file in 1Password
rotate-token: reissues the Connect token, updates 1Password, and reseeds Kubernetes

The bootstrap file is stored as the 1Password document item named:
  ${CONNECT_CREDENTIALS_DOC_NAME}
EOF
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

ensure_kubectl() {
  command -v kubectl >/dev/null 2>&1 || die "kubectl is required"
}

ensure_op() {
  command -v op >/dev/null 2>&1 || die "op is required"
}

ensure_namespace() {
  kubectl create namespace "${SECRET_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
}

apply_secret() {
  local secret_name="$1"
  shift
  kubectl -n "${SECRET_NAMESPACE}" create secret generic "${secret_name}" "$@" \
    --dry-run=client -o yaml | kubectl apply -f -
}

read_credentials_from_1password() {
  op document get "${CONNECT_CREDENTIALS_DOC_NAME}" --vault "${VAULT}"
}

read_token_from_1password() {
  op read "op://${VAULT}/${CONNECT_TOKEN_NAME}/password"
}

write_token_item() {
  local connect_token="$1"

  if op item get "${CONNECT_TOKEN_NAME}" --vault "${VAULT}" >/dev/null 2>&1; then
    op item edit "${CONNECT_TOKEN_NAME}" --vault "${VAULT}" password="${connect_token}" >/dev/null
  else
    op item create --vault="${VAULT}" --category=password --title="${CONNECT_TOKEN_NAME}" --tags="${CLUSTER_NAME}" password="${connect_token}" >/dev/null
  fi
}

write_document_item() {
  local document_path="$1"

  if op document get "${CONNECT_CREDENTIALS_DOC_NAME}" --vault "${VAULT}" >/dev/null 2>&1; then
    op document edit "${CONNECT_CREDENTIALS_DOC_NAME}" "${document_path}" \
      --vault "${VAULT}" \
      --file-name "${CONNECT_CREDENTIALS_DOC_NAME}" >/dev/null
  else
    op document create "${document_path}" \
      --vault "${VAULT}" \
      --title "${CONNECT_CREDENTIALS_DOC_NAME}" \
      --file-name "${CONNECT_CREDENTIALS_DOC_NAME}" >/dev/null
  fi
}

seed_kubernetes_secrets() {
  local connect_token="${1:-}"
  local connect_credentials_json
  local tmpdir

  connect_credentials_json="$(read_credentials_from_1password)"
  if [[ -z "${connect_token}" ]]; then
    connect_token="$(read_token_from_1password)"
  fi

  tmpdir="$(mktemp -d)"

  printf '%s' "${connect_credentials_json}" > "${tmpdir}/1password-credentials.json"

  apply_secret op-credentials \
    --from-literal=1password-credentials.json="$(base64 < "${tmpdir}/1password-credentials.json" | tr -d '\n')"

  apply_secret onepassword-connect-token \
    --from-literal=token="${connect_token}"

  rm -rf "${tmpdir}"
}

init_onepassword_connect() {
  ensure_op
  ensure_kubectl

  if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    die "init mode requires interactive 1Password auth; unset OP_SERVICE_ACCOUNT_TOKEN first"
  fi

  ensure_namespace

  tmpdir="$(mktemp -d)"
  pushd "${tmpdir}" >/dev/null
  credentials_path="${tmpdir}/1password-credentials.json"

  if ! op connect server get "${CONNECT_SERVER_NAME}" >/dev/null 2>&1; then
    echo "creating Connect server ${CONNECT_SERVER_NAME}"
    op connect server create "${CONNECT_SERVER_NAME}" --vaults "${VAULT}"
  else
    echo "Connect server ${CONNECT_SERVER_NAME} already exists"
  fi

  if ! op read "${CONNECT_TOKEN_REF}" >/dev/null 2>&1; then
    echo "creating Connect token ${CONNECT_TOKEN_NAME}"
    connect_token="$(op connect token create "${CONNECT_TOKEN_NAME}" --server "${CONNECT_SERVER_NAME}" --vault "${VAULT}")"
    write_token_item "${connect_token}"
  fi

  if [[ -f "1password-credentials.json" ]]; then
    mv "1password-credentials.json" "${credentials_path}"
  elif op document get "${CONNECT_CREDENTIALS_DOC_NAME}" --vault "${VAULT}" > "${credentials_path}" 2>/dev/null; then
    echo "loaded bootstrap document ${CONNECT_CREDENTIALS_DOC_NAME} from 1Password"
  else
    echo "missing bootstrap document ${CONNECT_CREDENTIALS_DOC_NAME} in vault ${VAULT}" >&2
    echo "run init once in a context where op connect server create generates 1password-credentials.json" >&2
    exit 1
  fi

  echo "storing bootstrap document ${CONNECT_CREDENTIALS_DOC_NAME} in vault ${VAULT}"
  write_document_item "${credentials_path}"

  popd >/dev/null
  rm -rf "${tmpdir}"
  seed_kubernetes_secrets
}

rotate_connect_token() {
  ensure_op
  ensure_kubectl

  if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    die "rotate-token mode requires interactive 1Password auth; unset OP_SERVICE_ACCOUNT_TOKEN first"
  fi

  ensure_namespace

  echo "reissuing Connect token ${CONNECT_TOKEN_NAME}"
  op connect token delete "${CONNECT_TOKEN_NAME}" --server "${CONNECT_SERVER_NAME}" || true

  connect_token="$(op connect token create "${CONNECT_TOKEN_NAME}" --server "${CONNECT_SERVER_NAME}" --vault "${VAULT}")"
  write_token_item "${connect_token}"
  seed_kubernetes_secrets "${connect_token}"
}

apply_onepassword_connect() {
  ensure_op
  ensure_kubectl

  if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    die "OP_SERVICE_ACCOUNT_TOKEN is required for apply mode"
  fi

  ensure_namespace
  seed_kubernetes_secrets
}

case "${MODE}" in
  -h|--help|help)
    usage
    exit 0
    ;;
  apply)
    apply_onepassword_connect
    ;;
  init)
    init_onepassword_connect
    ;;
  rotate-token)
    rotate_connect_token
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
