# Dev. Community Mauá - Setup

This repository contains the scripts to setup a new development repository for Dev. Community Mauá.

## How to use

1. Go to Issues
2. Create a new issue according to the template
3. Fill the issue with the information needed
4. Enjoy your new repository!

### Outsiders (Battlesnake)

Non-members of `Maua-Dev` may open a `[NEW_REPO]` issue **only** with a Battlesnake template:

- `battlesnake_fastapi_template`
- `battlesnake_nodejs_template`
- `battlesnake_java_template`
- `battlesnake_javascript_template`
- `battlesnake_rust_template`

For those repos the workflow provisions a **scoped temporary OIDC role** `gha-battlesnake-{repo}` (expires **2026-10-12**) and sets `AWS_DEPLOY_ROLE_ARN` on the new repository. Deploy permissions are limited to resources named `battlesnake-{repo}-*`.

### IAM bootstrap (maintainers)

One-time / idempotent setup of the permissions boundary + provisioner role:

1. Ensure org secret `AWS_ACCOUNT_ID_DEV` exists
2. Run workflow **Bootstrap Battlesnake IAM** (uses `GithubActionsRole` once)
3. After that, `create_repo` assumes `BattlesnakeRoleProvisioner` to mint per-repo roles

Cleanup runs daily via **Cleanup Battlesnake Roles** after 2026-10-12.

## Contributors

- Bruno Vilardi - [Brvilardi](https://github.com/Brvilardi)
- Hector Guerrini - [hectorguerrini](https://github.com/hectorguerrini)
- João Branco - [JoaoVitorBranco](https://github.com/JoaoVitorBranco)
- Vitor Soller - [VgsStudio](https://github.com/VgsStudio)
- Enrico Santarelli - [EnricoSantarelli](https://github.com/EnricoSantarelli)
- Rodrigo Morales - [RodrigoM2004](https://github.com/RodrigoM2004)
- Luigi Trevisan - [LuigiTrevisan](https://github.com/LuigiTrevisan)
- Rodrigo Siqueira [Rodrigosiq03](https://github.com/Rodrigosiq03)
- Lucas Crapino - [LucasCrapino](https://github.com/LucasCrapino)
