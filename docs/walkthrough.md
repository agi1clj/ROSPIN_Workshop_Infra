# Walkthrough: from your laptop to a running satellite app on Azure

You will take one app through the normal software lifecycle. Every step below has a tag:

`PLAN` -> `CODE` -> `BUILD` -> `TEST` -> `PROVISION` -> `DEPLOY` -> `MONITOR` -> `ITERATE`

| Item | Value |
|---|---|
| Time | 60 to 75 minutes (the machine work is about 12 minutes of waiting) |
| You need | GitHub account, Azure for Students subscription, a laptop |
| Tools | Git, Docker Desktop, Azure CLI (`az`), GitHub CLI (`gh`), Terraform 1.14 or newer |
| Windows | Run every command in **Git Bash** (comes with Git for Windows) or in **WSL2**. Do not use PowerShell. |
| macOS | zsh: run `setopt interactivecomments` once, or copy only the part before `#`. |
| Cost | Low. Container registry Basic (about 4.5 EUR per month) plus Container Apps (per use, with a free grant). Run `./scripts/cleanup.sh` when you finish. |

Your **team code** is 2 to 5 lowercase letters or digits, starting with a letter (examples: `t01`, `agi`). It is part of every Azure name. One team uses one Azure subscription (one member hosts the app). Every member can still run all steps in their own subscription.

Your repos are public, so GitHub Actions is free. The run logs show your Azure subscription ID and tenant ID. These IDs are not secrets and give no access. If you prefer, make the repos private in the repository settings.

Replace in all commands: `<team>` = your team code, `<github-user>` = your GitHub user name.

---

## Step 1 - PLAN: log in and check your Azure

```bash
gh auth login --scopes workflow    # GitHub.com -> HTTPS -> web browser
gh auth setup-git
az login                           # sign in with your student account
az account list --query "[?state=='Enabled'].{name:name, id:id}" -o table
az account set --subscription <subscription-id>   # use the ID: names can repeat (an expired subscription may share the name)
```

Check your credit in the Azure portal: search **Education** -> *Overview*. It must last until the end of the workshop.

## Step 2 - CODE: create your two repositories from the templates

```bash
gh repo create <team>-rospin-apps  --public --clone --template agi1clj/ROSPIN_Workshop_Apps
gh repo create <team>-rospin-infra --public --clone --template agi1clj/ROSPIN_Workshop_Infra
```

- **Apps** repo: the satellite app (backend, frontend, Dockerfiles, CI/CD workflows).
- **Infra** repo: Terraform modules and the bootstrap script.

Open both folders in your AI coding agent (Claude Code, Gemini CLI, Codex, Copilot). They read `AGENTS.md` first. Try: *"Explain what this repository does and how it is deployed."* Ask your agent before you run commands you do not understand.

## Step 3 - BUILD: run the app on your laptop

```bash
cd <team>-rospin-apps
docker compose up --build
```

- App: http://localhost:3000 (pick a region, look at the map and the NDVI chart)
- API docs: http://localhost:8000/docs

Docker builds two **images** (backend, frontend) and starts them as **containers**. The same images run in Azure later. Stop with `Ctrl+C`, then `docker compose down`.

## Step 4 - TEST: run the automated tests

```bash
docker run --rm -v "$PWD/backend:/app" -w /app python:3.13-slim \
  sh -c "pip install -q -r requirements-dev.txt && python -m pytest -q"
```

This runs the tests in a clean Python container, so you need no Python on your laptop. 14 tests pass (about 10 seconds). GitHub Actions runs the same tests on every push (open *Actions* in your Apps repo and look at the first `backend` run: job `test`). A pull request runs only the tests. Deployment runs only on `main`.

## Step 5 - PROVISION: bootstrap Azure (one time)

```bash
cd ../<team>-rospin-infra
./bootstrap/bootstrap.sh --check     # read-only preflight, changes nothing
./bootstrap/bootstrap.sh             # creates everything
```

Answer the questions: subscription, GitHub user, repo names (accept the defaults), team code, region (the script shows the regions your subscription allows).

Bootstrap creates, in about 2 minutes:

- A resource group with a storage account: the place where Terraform keeps its **state**.
- A managed identity for GitHub Actions with **OIDC** trust to `main` of your two repos. No password or secret exists anywhere.
- Azure roles for that identity, and GitHub repository variables in both repos.
- `terraform.tfvars` and `backend.hcl` (git-ignored) and `terraform init`.

If it stops with a permission message, show the output to the instructor.

## Step 6 - DEPLOY: infrastructure and application

The container apps need an image, and the registry that stores images does not exist yet. So the first deployment has three stages.

**6a. Infrastructure, stage 1: registry only (about 2 min)**

```bash
gh workflow run terraform --repo <github-user>/<team>-rospin-infra
gh run watch --repo <github-user>/<team>-rospin-infra
```

Choose the new run in the list. This creates `rg-rospin-<team>-dev` and the container registry (ACR).

**6b. Application: build and publish the first images (about 2 min)**

```bash
gh workflow run backend  --repo <github-user>/<team>-rospin-apps
gh workflow run frontend --repo <github-user>/<team>-rospin-apps
gh run watch --repo <github-user>/<team>-rospin-apps
```

Each workflow: test -> OIDC login -> `docker build` -> push to ACR. The last steps say the container app does not exist yet. That is expected.

**6c. Infrastructure, stage 2: create the Container Apps (about 3 min)**

```bash
gh variable set CREATE_WEB_APPS --body true --repo <github-user>/<team>-rospin-infra
gh workflow run terraform --repo <github-user>/<team>-rospin-infra
gh run watch --repo <github-user>/<team>-rospin-infra
```

Never set `CREATE_WEB_APPS` back to `false`: that would delete your apps. Read the URLs from the end of the run (job *deploy* -> step *terraform output*) or locally:

```bash
cd terraform/environments/dev
terraform output frontend_url
terraform output backend_url
cd ../../..
```

> If `CI_CAN_ASSIGN_ROLES` is `false` (bootstrap prints a warning), run `terraform apply` in `terraform/environments/dev` on your laptop for this stage instead of the workflow.

Open the frontend URL. The first start can take 1 to 3 minutes.

## Step 7 - MONITOR: is it healthy and which version runs?

```bash
curl <backend_url>/health           # {"status":"ok","version":"<git commit>"}
curl <frontend_url>/version.txt     # the same commit
az extension add --name containerapp --only-show-errors
az containerapp logs show -g rg-rospin-<team>-dev -n <backend app name> --tail 20
az containerapp revision list -g rg-rospin-<team>-dev -n <backend app name> -o table
```

The backend app name is in `terraform output backend_webapp_name`. Azure also probes `/health` and `/healthz` itself and restarts a container that fails. In the portal: Resource group -> your container app -> *Log stream* and *Metrics*.

Try *Live Sentinel-2* in the app. It reads real satellite images from the public AWS archive from inside your container (about 1 minute).

## Step 8 - ITERATE: change the app, watch it deploy

Ask your AI agent to make a change, for example: *"Add a new region for my city."* The agent must add the region in `backend/app/regions.py` and create its sample data with `docker compose run --rm -v "$PWD/backend/app:/app/app" backend python -m app.export_sample <region-id>` (about 1 minute, needs internet). Without sample data the test fails and CI blocks the deploy: this is the safety net working. Review the diff yourself.

```bash
cd ../<team>-rospin-apps
git add -A
git commit -m "feat(backend): add my city region"
git push
```

Watch *Actions*. After about 2 minutes `curl <backend_url>/health` shows your new commit hash. This is CI/CD: **commit -> test -> build -> push image -> deploy -> verify**.

Check the Terraform side too:

```bash
cd ../<team>-rospin-infra/terraform/environments/dev
terraform plan        # compares the code with Azure
terraform output
```

After a deployment, `terraform plan` can list small in-place updates on the two apps (`cooldown_period_in_seconds`, `polling_interval_in_seconds`, probe `transport`, `traffic_weight`). Azure does not send these default values back, so Terraform always sees a difference. They change nothing, and Terraform never touches the image. Read the plan, and you will see that it is only this.

## Step 9 - SUBMIT

Send us one message with:

1. Team code and member names.
2. Link to your Apps repo and your Infra repo.
3. The live **frontend URL** and **backend URL** (`<backend_url>/docs`).
4. Link to one green *Actions* run of `terraform`, `backend` and `frontend`.
5. One sentence: what did you change with your AI agent?

## Clean up (when you finish)

```bash
cd <team>-rospin-infra
./scripts/cleanup.sh
```

It asks `yes` before each of three steps: delete the app resource group (stops the cost), delete the GitHub identity, delete the state storage.

## Common problems

| Message | Fix |
|---|---|
| `Not logged in to Azure` / `GitHub` | Run `az login` / `gh auth login --scopes workflow` |
| Region blocked by policy | Pick a region from the list the script prints |
| `Image backend:latest not found` in the terraform run | Do step 6b first, wait for green, then 6c |
| Azure login fails in Actions | You renamed a repo. Run `./bootstrap/bootstrap.sh` again |
| `MissingSubscription` / path starting with `C:/Program Files/Git` | You used PowerShell or Git Bash without the script fix. Use Git Bash and the unmodified scripts |
| Container app not ready | Wait 1 to 3 minutes and retry the `/health` URL |
