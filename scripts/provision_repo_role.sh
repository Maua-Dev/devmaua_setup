#!/usr/bin/env bash
# Provision a per-repo Battlesnake GitHub Actions OIDC role and set repo secrets.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID is required}"
REPO_NAME="${REPO_NAME:?REPO_NAME is required}"
FAMILY="${FAMILY:?FAMILY is required}" # cdk | tf
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
ORG="${ORG:-Maua-Dev}"
EXPIRY="${EXPIRY:-2026-10-12T23:59:59Z}"

ROLE_NAME="gha-battlesnake-${REPO_NAME}"
# IAM role names max 64 chars
if [[ ${#ROLE_NAME} -gt 64 ]]; then
  echo "Role name too long: ${ROLE_NAME} (${#ROLE_NAME} > 64)"
  exit 1
fi

case "$FAMILY" in
  cdk) POLICY_TPL="${ROOT_DIR}/iam/gha-battlesnake-cdk-policy.json.tpl" ;;
  tf)  POLICY_TPL="${ROOT_DIR}/iam/gha-battlesnake-tf-policy.json.tpl" ;;
  *)
    echo "Unknown FAMILY=${FAMILY} (expected cdk|tf)"
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

render() {
  local src="$1"
  local dest="$2"
  sed -e "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" \
      -e "s/\${REPO_NAME}/${REPO_NAME}/g" \
      "$src" > "$dest"
}

render "${ROOT_DIR}/iam/gha-battlesnake-trust.json.tpl" "${TMP_DIR}/trust.json"
# Enforce expiry from env if template still has fixed date
sed -i.bak "s/2026-10-12T23:59:59Z/${EXPIRY}/g" "${TMP_DIR}/trust.json"
render "$POLICY_TPL" "${TMP_DIR}/policy.json"

echo "==> Creating/updating role ${ROLE_NAME} (family=${FAMILY})"
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document "file://${TMP_DIR}/trust.json"
else
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "file://${TMP_DIR}/trust.json" \
    --description "Battlesnake GHA deploy role for ${ORG}/${REPO_NAME} (expires ${EXPIRY})" \
    --tags \
      Key=battlesnake-event,Value=2026 \
      Key=battlesnake-repo,Value="${REPO_NAME}" \
      Key=battlesnake-family,Value="${FAMILY}" \
      Key=expiry,Value=2026-10-12 \
      Key=managed-by,Value=devmaua_setup >/dev/null
fi

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "BattlesnakeRepoScoped" \
  --policy-document "file://${TMP_DIR}/policy.json"

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "ROLE_ARN=${ROLE_ARN}"

echo "==> Setting GitHub Actions secrets on ${ORG}/${REPO_NAME}"
# gh secret set needs repo write; GITHUB_TOKEN already in env from App token
set_secret() {
  local name="$1"
  local body="$2"
  local tries=0
  until gh secret set "$name" --repo "${ORG}/${REPO_NAME}" --body "${body}"; do
    tries=$((tries + 1))
    if [[ $tries -ge 3 ]]; then
      echo "WARN: failed to set repo secret ${name} after retries (role still provisioned)"
      return 0
    fi
    sleep 2
  done
  if gh api "repos/${ORG}/${REPO_NAME}/environments/dev" >/dev/null 2>&1; then
    gh secret set "$name" --repo "${ORG}/${REPO_NAME}" --env dev --body "${body}" || true
  fi
}

set_secret AWS_DEPLOY_ROLE_ARN "${ROLE_ARN}"
set_secret AWS_ACCOUNT_ID_DEV "${AWS_ACCOUNT_ID}"

echo "Provisioned ${ROLE_ARN} for ${ORG}/${REPO_NAME}"
