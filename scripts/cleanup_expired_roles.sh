#!/usr/bin/env bash
# Delete Battlesnake GHA roles tagged for the 2026 event after expiry date.
# Or delete an explicit list via FORCE_ROLES="role1 role2 ..." (for throwaway cleanup).
set -euo pipefail

delete_role() {
  local ROLE_NAME="$1"
  echo "Deleting role ${ROLE_NAME}"
  for P in $(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames[]' --output text 2>/dev/null); do
    [[ -n "$P" && "$P" != "None" ]] || continue
    aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$P"
  done
  for ARN in $(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null); do
    [[ -n "$ARN" && "$ARN" != "None" ]] || continue
    aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$ARN"
  done
  aws iam delete-role --role-name "$ROLE_NAME"
}

if [[ -n "${FORCE_ROLES:-}" ]]; then
  echo "==> Force-deleting roles: ${FORCE_ROLES}"
  for ROLE_NAME in ${FORCE_ROLES}; do
    if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
      delete_role "$ROLE_NAME"
    else
      echo "Role ${ROLE_NAME} not found; skipping"
    fi
  done
  echo "Force cleanup done."
  exit 0
fi

CUTOFF="${CUTOFF:-2026-10-12}"
TODAY="${TODAY:-$(date -u +%Y-%m-%d)}"

if [[ "$TODAY" < "$CUTOFF" ]]; then
  echo "Today (${TODAY}) is before cutoff (${CUTOFF}); nothing to delete."
  exit 0
fi

echo "==> Listing IAM roles with prefix gha-battlesnake-"
NEXT=""
while :; do
  if [[ -n "$NEXT" ]]; then
    RESP=$(aws iam list-roles --path-prefix / --max-items 100 --starting-token "$NEXT")
  else
    RESP=$(aws iam list-roles --max-items 100)
  fi

  echo "$RESP" | jq -r '.Roles[].RoleName' | while read -r ROLE_NAME; do
    [[ "$ROLE_NAME" == gha-battlesnake-* ]] || continue
    TAGS=$(aws iam list-role-tags --role-name "$ROLE_NAME" --query 'Tags' --output json)
    EVENT=$(echo "$TAGS" | jq -r '.[] | select(.Key=="battlesnake-event") | .Value' | head -1)
    if [[ "$EVENT" != "2026" ]]; then
      continue
    fi
    delete_role "$ROLE_NAME"
  done

  NEXT=$(echo "$RESP" | jq -r '.NextToken // empty')
  [[ -z "$NEXT" ]] && break
done

echo "Cleanup done."
