#!/usr/bin/env bash
# Bootstrap Battlesnake IAM foundation in the DEV account.
# Intended to run from GitHub Actions with GithubActionsRole (one-time / idempotent).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID is required}"
AWS_REGION="${AWS_REGION:-us-east-1}"
BOUNDARY_NAME="pb-battlesnake-participant"
PROVISIONER_ROLE_NAME="BattlesnakeRoleProvisioner"
OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

render() {
  local src="$1"
  local dest="$2"
  sed -e "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" \
      -e "s/\${REPO_NAME}/PLACEHOLDER/g" \
      "$src" > "$dest"
}

echo "==> Ensuring permissions boundary ${BOUNDARY_NAME}"
BOUNDARY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${BOUNDARY_NAME}"
if aws iam get-policy --policy-arn "$BOUNDARY_ARN" >/dev/null 2>&1; then
  echo "Boundary exists; creating a new default version"
  aws iam create-policy-version \
    --policy-arn "$BOUNDARY_ARN" \
    --policy-document "file://${ROOT_DIR}/iam/pb-battlesnake-participant.json" \
    --set-as-default >/dev/null
  # Keep at most 5 versions
  for v in $(aws iam list-policy-versions --policy-arn "$BOUNDARY_ARN" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text); do
    aws iam delete-policy-version --policy-arn "$BOUNDARY_ARN" --version-id "$v" || true
  done
else
  aws iam create-policy \
    --policy-name "$BOUNDARY_NAME" \
    --policy-document "file://${ROOT_DIR}/iam/pb-battlesnake-participant.json" \
    --description "Permissions boundary for Battlesnake participant roles (event 2026)" >/dev/null
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

render "${ROOT_DIR}/iam/provisioner-trust.json.tpl" "${TMP_DIR}/provisioner-trust.json"
# Remove unused REPO placeholder if any
sed -i.bak "s/PLACEHOLDER//g" "${TMP_DIR}/provisioner-trust.json" 2>/dev/null || true
render "${ROOT_DIR}/iam/provisioner-policy.json.tpl" "${TMP_DIR}/provisioner-policy.json"

echo "==> Ensuring provisioner role ${PROVISIONER_ROLE_NAME}"
if aws iam get-role --role-name "$PROVISIONER_ROLE_NAME" >/dev/null 2>&1; then
  aws iam update-assume-role-policy \
    --role-name "$PROVISIONER_ROLE_NAME" \
    --policy-document "file://${TMP_DIR}/provisioner-trust.json"
else
  aws iam create-role \
    --role-name "$PROVISIONER_ROLE_NAME" \
    --assume-role-policy-document "file://${TMP_DIR}/provisioner-trust.json" \
    --description "Provisions per-repo Battlesnake GitHub Actions roles from devmaua_setup" \
    --tags Key=battlesnake-event,Value=2026 Key=managed-by,Value=devmaua_setup >/dev/null
fi

aws iam put-role-policy \
  --role-name "$PROVISIONER_ROLE_NAME" \
  --policy-name "BattlesnakeProvisionerInline" \
  --policy-document "file://${TMP_DIR}/provisioner-policy.json"

echo "==> Bootstrap complete"
echo "BOUNDARY_ARN=${BOUNDARY_ARN}"
echo "PROVISIONER_ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROVISIONER_ROLE_NAME}"
echo "OIDC_PROVIDER_ARN=${OIDC_PROVIDER_ARN}"
