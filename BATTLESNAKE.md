# Battlesnake: outsider repo creation + scoped OIDC deploy

Technical reference for maintainers and agents working on `devmaua_setup` and the Battlesnake templates.

## Goal

Allow **non-members** of `Maua-Dev` to create a public Battlesnake repo via issue, deploy to the **shared DEV AWS account**, and only touch resources for **their** repo — without giving them (or their Actions) the org-wide `GithubActionsRole`.

| Decision | Choice |
|---|---|
| AWS account | Same DEV account as the rest of Maua-Dev |
| AuthZ | Outsiders: Battlesnake templates only. Members: unchanged for other templates |
| IAM model | **One OIDC role per participant repo** (`gha-battlesnake-{repo}`) |
| Scope | Resource name prefix `battlesnake-{repo_slug}-*` + permissions boundary |
| Expiry | Trust `DateLessThan` = `2026-10-12T23:59:59Z` + scheduled cleanup |

Non-Battlesnake member repos still use the legacy broad role until migrated.

## High-level flow

```text
outsider opens [NEW_REPO] issue (Battlesnake template)
        │
        ▼
create_repo.yml  ──membership?──► outsider + non-BS template → close issue
        │
        ├── create empty public repo
        ├── disable Actions
        ├── push template contents to `dev`
        ├── author = repo admin; skip Back-end/Front-end teams; skip branch protection
        ├── assume BattlesnakeRoleProvisioner
        ├── create/update gha-battlesnake-{repo} + set secrets
        ├── re-enable Actions
        └── empty commit on `dev` → Instant CD
                │
                ▼
participant CD assumes AWS_DEPLOY_ROLE_ARN
                │
                ▼
deploys only battlesnake-{slug}-* (Lambda / API GW or Function URL / etc.)
```

## AuthZ (who can create what)

Implemented in `.github/workflows/create_repo.yml` (`process_issue`):

1. Check org membership via `gh api /orgs/Maua-Dev/members/{user}`.
2. If **not** a member:
   - Template must be in the Battlesnake allowlist (see below) or the issue is commented + closed.
   - Force `privacy_type=public`, `team=None`.
3. If **member**: existing behavior (any template, teams, branch protection on public repos).

Allowlist:

- `battlesnake_fastapi_template` (CDK / Python)
- `battlesnake_nodejs_template` (CDK / TypeScript)
- `battlesnake_java_template` (Terraform)
- `battlesnake_javascript_template` (Terraform)
- `battlesnake_rust_template` (Terraform)

**Insider Battlesnake repos also get the scoped role** (same provision path) — they must not keep using `GithubActionsRole` for deploy.

## Naming contract (mandatory)

IAM policies match **hyphenated** slugs. Underscores in the GitHub repo name are converted:

```bash
REPO_SLUG="${REPO_NAME//_/-}"   # my_snake → my-snake
```

Standard names (templates must follow):

| Resource | Name pattern |
|---|---|
| CFN stack (CDK) | `battlesnake-{slug}-{stage}` |
| Lambda | `battlesnake-{slug}-lambda-{stage}` |
| Lambda exec role | `battlesnake-{slug}-role-{stage}` (no `/battlesnake/` IAM path — path breaks ARN wildcards) |
| API GW (TF) | `battlesnake-{slug}-api-{stage}` |
| Alarm (CDK) | `battlesnake-{slug}-alarm-{stage}` |
| Layer (Node CDK) | `battlesnake-{slug}-layer-{stage}` |
| TF state key | `app/{slug}/terraform.tfstate` (also allow `app/{REPO_NAME}/` for underscore legacy) |

Templates must set `function_name` / `roleName` / stack name explicitly. CDK auto-names break ARN scoping.

## IAM layout (DEV account)

### 1. Permissions boundary — `pb-battlesnake-participant`

Caps what a participant Lambda exec role (and related creates) can ever get: Lambda, logs, CW, CFN, S3, API GW, shared SNS `sns-battlesnake`, limited IAM on `battlesnake-*` / CDK bootstrap roles. No IAM admin.

Also allows `kms:Decrypt` / `kms:DescribeKey` on account keys: Lambda encrypts **environment variables** at rest with the account `aws/lambda` CMK, and the **exec role** must decrypt them on cold start. Without this, any function that sets env vars (Node `STAGE`, JS `NODE_OPTIONS`, Rust `RUST_LOG`, etc.) fails invoke with `AccessDeniedException` on `kms:Decrypt` and Function URL/API GW return 502 — often with **no app logs**. FastAPI currently sets no Lambda env vars, so it could work before this grant.

Updating this managed policy (Bootstrap Battlesnake IAM) applies immediately to all roles that use the boundary; no per-repo redeploy required for the KMS fix.

File: `iam/pb-battlesnake-participant.json`

### 2. Provisioner — `BattlesnakeRoleProvisioner`

Trusted only by OIDC from `repo:Maua-Dev/devmaua_setup:*`. Used by `create_repo` / `reprovision_battlesnake_role` / cleanup to create per-repo roles and set GitHub secrets.

Bootstrap (once): workflow **Bootstrap Battlesnake IAM** (`bootstrap_battlesnake_iam.yml`) using org secret `AWS_ACCOUNT_ID_DEV` + temporary assume of `GithubActionsRole`.

Files: `iam/provisioner-*.json.tpl`, `scripts/bootstrap_iam.sh`

### 3. Per-repo role — `gha-battlesnake-{REPO_NAME}`

- **Trust** (`iam/gha-battlesnake-trust.json.tpl`): GitHub OIDC; `sub` patterns cover both legacy `repo:Maua-Dev/{repo}:…` and org/repo-id forms `repo:Maua-Dev@73619687/{repo}@…`. Hard expiry via `DateLessThan`.
- **Identity policy**: family-specific template rendered with `REPO_NAME` / `REPO_SLUG` / account id.
  - CDK: `iam/gha-battlesnake-cdk-policy.json.tpl` (Lambda, logs, alarms, SNS, CFN, CDK asset buckets, PassRole to prefixed + `cdk-hnb659fds-*`).
  - TF: `iam/gha-battlesnake-tf-policy.json.tpl` (Lambda, API GW, logs, S3 state family buckets with prefix conditions, DynamoDB locks).
- **PassRole**: do **not** require `iam:PermissionsBoundary` on PassRole (that condition is absent on PassRole requests and blocks `lambda:CreateFunction`). Boundary is enforced on `CreateRole`.
- **logs:DescribeLogGroups** (and similar describe APIs) need `Resource: "*"` — they do not support resource-level ARNs. Scoped `logs:*` remains on `/aws/lambda/battlesnake-{slug}-*`.

Script: `scripts/provision_repo_role.sh`  
Also sets repo secrets:

- `AWS_DEPLOY_ROLE_ARN` = `arn:aws:iam::{account}:role/gha-battlesnake-{repo}`
- `AWS_ACCOUNT_ID_DEV`

Reprovision without recreating the GitHub repo: workflow **Reprovision Battlesnake Role**.

## create_repo Battlesnake sequence (race fix)

`gh repo create --template` commits workflows immediately and Instant CD can run **before** secrets exist → `configure-aws-credentials` fails with *Could not load credentials from any providers*.

Current order for Battlesnake:

1. Create **empty** repo.
2. **Disable** Actions.
3. Clone template → push to `dev` (workflows present but idle).
4. Collaborators / teams / outsider UX comments.
5. Assume provisioner → `provision_repo_role.sh`.
6. **Enable** Actions + empty commit `chore: trigger CD after OIDC secrets provisioned`.

Triggers: `issues: [opened, reopened]` (reopen recovers stuck issues after workflow YAML fixes).

## Template families

### CDK (FastAPI, Node.js)

- Region: FastAPI often `sa-east-1`; Node CD uses `us-east-1` — follow each template’s workflow.
- Deploy: Function URL (no API GW).
- Workflows must use `role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}` (no fallback to `GithubActionsRole`).
- Export `REPO_SLUG` into the CDK env; IaC must use slug for resource names (not raw underscored `REPO_NAME`).
- Do not publish AWS Console CloudWatch/Lambda links in step summary / CfnOutputs — outsiders have no console access. Surface the Function URL only.

### Terraform (Java, JavaScript, Rust)

- Region: `us-east-1`, API Gateway fronting Lambda.
- Shared family state buckets / lock tables (`battlesnake-*-template-terraform-state*`). Bootstrap job must **resolve** existing shared bucket/table names — scoped roles cannot `GetBucketPolicy` / fully admin shared infra.
- App state key: `app/${REPO_SLUG}/…`.
- Prefer **not** managing `aws_cloudwatch_log_group` in TF (align with Java): Lambda creates the group on invoke. Managing it needs DescribeLogGroups and orphans state after partial applies.
- CD summary: only `api_url_base`.

## Outsider UX notes

- GitHub **hides Actions logs from anonymous viewers** even on public repos — author must be signed in.
- Author gets **admin** collaborator invite; they must accept it.
- Outsiders skip branch protection so they can push `dev` without PR friction for the event.
- Participants do not get CloudWatch console access by design; debug via Battlesnake playground / hitting the public URL.

## Workflows in this repo

| Workflow | Purpose |
|---|---|
| `create_repo.yml` | Issue → repo factory + Battlesnake provision |
| `bootstrap_battlesnake_iam.yml` | One-time boundary + provisioner |
| `reprovision_battlesnake_role.yml` | Recreate/update one repo’s role + secrets |
| `cleanup_battlesnake_roles.yml` | After 2026-10-12 delete tagged roles; or `workflow_dispatch` with `force_roles` for throwaways |

Cleanup script: `scripts/cleanup_expired_roles.sh` (`FORCE_ROLES="gha-battlesnake-foo …"` bypasses date cutoff).

## Agent / maintainer checklist

When changing this system:

1. **Naming**: any new AWS resource must fit `battlesnake-{slug}-*` or an explicit shared exception (CDK bootstrap, TF state bucket list, SNS topic).
2. **Policies**: edit `iam/*.json.tpl`, then **reprovision** existing participant roles (templates alone do not update AWS).
3. **Templates**: keep CD on `AWS_DEPLOY_ROLE_ARN`; never reintroduce `GithubActionsRole` for Battlesnake participants.
4. **YAML in create_repo**: multiline strings inside `run: \|` must stay indented — unindented heredoc bodies invalidate the whole workflow (issues stop triggering).
5. **Do not** use `gh repo create --template` for Battlesnake without the Actions-disabled dance.
6. Throwaway test repos: delete the GitHub repo **and** force-delete `gha-battlesnake-{repo}` via cleanup workflow.

## Known limitations

- API Gateway create (`apigateway:POST /restapis`) is weakly ARN-scoped; mitigation is boundary + naming + per-repo trust.
- CDK asset / bootstrap roles remain shared (required for CDK).
- Trust expiry and cleanup date are hardcoded around the 2026 event window.
- Org Actions / issue settings must allow non-members to open issues on `devmaua_setup`.

## Related paths

```text
.github/workflows/create_repo.yml
.github/workflows/bootstrap_battlesnake_iam.yml
.github/workflows/reprovision_battlesnake_role.yml
.github/workflows/cleanup_battlesnake_roles.yml
iam/
scripts/bootstrap_iam.sh
scripts/provision_repo_role.sh
scripts/cleanup_expired_roles.sh
```

Template remotes (not in this repo): `Maua-Dev/battlesnake_{fastapi,nodejs,java,javascript,rust}_template`.
