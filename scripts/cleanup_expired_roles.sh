#!/usr/bin/env bash
# Delete Battlesnake GHA roles tagged for the 2026 event after expiry date.
set -euo pipefail

CUTOFF="${CUTOFF:-2026-10-12}"
TODAY="${TODAY:-$(date -u +%Y-%m-%d)}"

if [[ "$TODAY" < "$CUTOFF" ]]; then
  echo "Today (${TODAY}) is before cutoff (${CUTOFF}); nothing to delete."
  exit 0
fi

echo "==> Listing IAM roles with prefix gha-battlesnake-"
# Paginate roles
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
    echo "Deleting expired role ${ROLE_NAME}"
    # Detach inline policies
    for P in $(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames[]' --output text); do
      aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$P"
    done
    for ARN in $(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text); do
      aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$ARN"
    done
    aws iam delete-role --role-name "$ROLE_NAME"
  done

  NEXT=$(echo "$RESP" | jq -r '.NextToken // empty')
  [[ -z "$NEXT" ]] && break
done

echo "Cleanup done."
