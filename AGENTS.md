# AGENTS.md

Workshop project (ROSPIN Space Talks): Azure infrastructure for the companion Apps repository (`*-rospin-apps`), deployed with Terraform and GitHub Actions. Keep it simple: no AKS, VNets, Key Vault or extra tooling unless asked.

## Layout
- `terraform/environments/dev/` the only root module (remote state key `dev.tfstate`). Names and tags live in `locals.tf`.
- `terraform/modules/<service>/` one small module per service (`container-registry`, `container-apps`): `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
- `bootstrap/bootstrap.sh` one-time setup: creates your Apps repo from the template, Terraform state storage, a managed identity for GitHub Actions with OIDC, roles, GitHub variables.
- `scripts/cleanup.sh` deliberate teardown. `docs/walkthrough.md` the student tutorial.

## Verify before finishing (no Azure needed)
- `terraform fmt -check -recursive terraform`
- `cd terraform/environments/dev && terraform init -backend=false && terraform validate && terraform test`
- `shellcheck bootstrap/*.sh scripts/*.sh`

## Rules
- Never run `terraform apply`/`destroy`, `bootstrap.sh` or `cleanup.sh` against Azure without explicit user approval. Show `terraform plan` first.
- Follow the HashiCorp Terraform style guide: every variable has `type` and `description`, every output a `description`; no provisioners; no hard-coded IDs or secrets; one resource type per module concern.
- Resource names start with `rospin` and include the team code, for example `rg-rospin-<team>-dev`.
- Do not commit `terraform.tfvars`, `backend.hcl`, `bootstrap.env` or state. Do commit `.terraform.lock.hcl`.
- `ignore_changes` covers only the container image. Apps CI owns image tags. Never widen it.
- `CREATE_WEB_APPS` must never go back to `false` once the apps exist (it would delete them).
- New roles Terraform assigns must be added to `ASSIGNABLE_ROLE_IDS` in `bootstrap.sh`; new resource providers to both `bootstrap.sh` and `providers.tf`.
- Commits follow Conventional Commits: `type(scope): summary` (feat, fix, docs, refactor, test, ci, chore).

## Agent skills
Claude Code offers these when you trust the folder (`.claude/settings.json`): HashiCorp `terraform-style-guide` and `terraform-test`, `terraform-skill` (Anton Babenko), Microsoft `azure-skills` (azure-validate, azure-diagnostics, azure-deploy). Other agents: `docs/ai-setup.md`.
