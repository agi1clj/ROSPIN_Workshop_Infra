# Walkthrough: from your laptop to a running satellite app on Azure

You take one app through the normal software lifecycle. Every step has a tag:

`PLAN` -> `CODE` -> `BUILD` -> `TEST` -> `PROVISION` -> `DEPLOY` -> `MONITOR` -> `ITERATE`

| Item | Value |
|---|---|
| Time | 60 to 75 minutes (about 12 minutes of it is waiting for machines). Install the tools the day before. |
| You need | GitHub account, Azure for Students subscription, a laptop with 8 GB RAM and 15 GB free disk |
| Windows | Run every command in **Git Bash** (it comes with Git for Windows). Do not use PowerShell. |
| Cost | Low. The container registry costs about 4.5 EUR per month, even when nobody uses the app. Container Apps bills per use, with a free grant. **Run the clean-up step the same day you finish.** |

## Before you start (do this the day before, about 30 minutes)

Tick each box.

- [ ] GitHub account: <https://github.com/signup>
- [ ] Azure for Students (use your university email, no credit card): <https://azure.microsoft.com/free/students>
- [ ] Git for Windows (includes Git Bash): <https://git-scm.com/download/win>
- [ ] Docker Desktop (turn on "Use WSL 2", then restart the PC): <https://www.docker.com/products/docker-desktop>
- [ ] Azure CLI: <https://learn.microsoft.com/cli/azure/install-azure-cli>
- [ ] GitHub CLI: <https://cli.github.com>
- [ ] Terraform 1.14 or newer: <https://developer.hashicorp.com/terraform/install>
- [ ] An AI coding agent for step 8 (optional, a manual way exists): Claude Code, Gemini CLI, Codex or Copilot

After you install, **close Git Bash and open a new one**. Start Docker Desktop and wait until it says "running". Then check each tool. Each command must print a version:

```bash
git --version
docker --version
az version
gh --version
terraform version
```

You must be **Owner** of your Azure subscription. A student subscription gives you this by default.

How to read this guide:

- Type the real value. Do **not** type the `<` and `>` signs. Example: `<team>` becomes `t01`.
- Your **team code** is 2 to 5 lowercase letters or digits, starting with a letter (examples: `t01`, `agi`). It is part of every Azure name. One team uses one Azure subscription (one member hosts the app). Every member can still run all steps in their own subscription.
- `<github-user>` is your GitHub user name.
- Every step has a **You are here** line. It tells you which folder to be in.
- Keep both repositories in one parent folder. This guide uses `~/rospin`.

### Words you will meet

| Word | Simple meaning |
|---|---|
| Azure subscription | Your Azure account. It holds your resources and your free credit. |
| Resource group | A folder in Azure. When you delete the folder, everything inside is gone. |
| Terraform | A tool that creates Azure resources from text files. |
| Terraform state | A file where Terraform remembers what it made. |
| Docker image | An app packed with everything it needs. |
| Container | A running copy of an image. |
| Container Apps | The Azure service that runs your containers. |
| ACR (container registry) | A private store for your images in Azure. |
| GitHub Actions | GitHub robots that run your tests and deployments on every push. |
| OIDC | A way for GitHub to sign in to Azure with a short-lived pass. There is no password. |
| Managed identity | A login that Azure gives to a service, not to a person. |

---

## Step 1 - PLAN: log in

**You are here:** any folder, in Git Bash.

```bash
gh auth login --scopes workflow
gh auth setup-git
az login
az account list --query "[?state=='Enabled'].{name:name, id:id}" -o table
az account set --subscription <subscription-id>
```

- `gh auth login` asks questions. Answer: **GitHub.com**, **HTTPS**, **Y** (authenticate Git), **Login with a web browser**. Copy the 8-character code, press Enter, and paste the code in the browser.
- `az login` opens a browser. Sign in with your university account. If it shows a list of subscriptions, press Enter to keep the default.
- For `<subscription-id>`, copy the `id` value from the table. Use the ID because two subscriptions can have the same name.

**Success:** the table shows your Azure for Students subscription with State `Enabled`. If the table is empty, your subscription is not active: stop and fix it first. Check your credit in the Azure portal: search **Education**, then *Overview*.

## Step 2 - CODE: create your two repositories from the templates

**You are here:** any folder. First make the parent folder:

```bash
mkdir -p ~/rospin && cd ~/rospin
gh repo create <team>-rospin-apps  --public --clone --template agi1clj/ROSPIN_Workshop_Apps
gh repo create <team>-rospin-infra --public --clone --template agi1clj/ROSPIN_Workshop_Infra
ls
```

- The **Apps** repo has the satellite app: backend, frontend, Dockerfiles, CI/CD workflows.
- The **Infra** repo has the Terraform modules and the bootstrap script.

**Success:** `ls` shows the two folders `<team>-rospin-apps` and `<team>-rospin-infra`.

Open both folders in your AI coding agent. Agents read `AGENTS.md` first. Try: *"Explain what this repository does and how it is deployed."* No agent yet? Skip this. Step 8 has a manual way.

## Step 3 - BUILD: run the app on your laptop

**You are here:** `~/rospin/<team>-rospin-apps`. Docker Desktop must be running.

```bash
cd ~/rospin/<team>-rospin-apps
docker compose up --build
```

The first build takes 3 to 8 minutes. Docker builds two **images** (backend and frontend) and starts them as **containers**.

**Success:** the terminal prints lines from `backend` and `frontend`, and stays busy. Open <http://localhost:3000>: pick a region, look at the map and the NDVI chart. The API documentation is at <http://localhost:8000/docs>.

Keep this terminal open while you look. Stop with `Ctrl+C`, then run `docker compose down`. If you see "port is already allocated", close the other program that uses port 3000 or 8000.

## Step 4 - TEST: run the automated tests

**You are here:** `~/rospin/<team>-rospin-apps`.

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD/backend:/app" -w /app python:3.13-slim \
  sh -c "pip install -q -r requirements-dev.txt && python -m pytest -q"
```

This runs the tests in a clean Python container, so you need no Python on your laptop. (`MSYS_NO_PATHCONV=1` stops Git Bash from changing the path. It does no harm on Mac and Linux.)

**Success:** the last line says `14 passed`. If a test fails, read the message above it. Do not go on until all tests pass.

GitHub runs the same tests on every push. Deployment runs only from the `main` branch, after the tests pass.

## Step 5 - PROVISION: bootstrap Azure (one time)

**You are here:** `~/rospin/<team>-rospin-infra`.

```bash
cd ~/rospin/<team>-rospin-infra
./bootstrap/bootstrap.sh --check
./bootstrap/bootstrap.sh
```

- `--check` only reads. It changes nothing. **Success:** green text `Preflight passed.` If you see `problem(s) found`, read the lines that start with `!` and use the table at the end of this guide.
- The second command does the work. Press Enter to accept the default for the subscription, the GitHub user, the repository names and the region. **Type your team code** (example: `t01`).
- It takes 2 to 5 minutes. Some lines look stuck, for example `Attempt 3/20 failed`. Wait. Azure needs time to apply new roles. Do not press `Ctrl+C`.

**Success:** green text `Bootstrap complete.` The script is safe to run again if it stops. If it says "Some steps need someone with more Azure permissions", copy **all** the text and send it to your instructor.

What it created:

- A resource group with a storage account: the place for the Terraform **state**.
- A managed identity for GitHub Actions. **OIDC** trust: only the `main` branch of your two repos can use it. No password or secret exists anywhere.
- Azure roles for that identity, and settings (GitHub repository variables) in both repos.
- `terraform.tfvars` and `backend.hcl` (git-ignored), then `terraform init`.

## Step 6 - DEPLOY: infrastructure and application

The container apps need an image. The registry that stores images does not exist yet. So the first deployment has three stages. Total waiting time is about 7 minutes.

`gh run watch` shows a list. Use the arrow keys and press Enter on the newest run. If the list is empty, wait 10 seconds and run it again. **Success** is a green check and `completed with 'success'`. If a run fails, run `gh run view --log-failed --repo <github-user>/<team>-rospin-infra` (or `-apps`) and use the table at the end.

**6a. Infrastructure, stage 1: resource group and registry (about 2 min)**

**You are here:** any folder.

```bash
gh workflow run terraform --repo <github-user>/<team>-rospin-infra
sleep 10
gh run watch --repo <github-user>/<team>-rospin-infra
```

If you see `could not find any workflows`, wait 30 seconds and run it again.

**6b. Application: build and publish the first images (about 2 min)**

```bash
gh workflow run backend  --repo <github-user>/<team>-rospin-apps
gh workflow run frontend --repo <github-user>/<team>-rospin-apps
sleep 10
gh run watch --repo <github-user>/<team>-rospin-apps
gh run watch --repo <github-user>/<team>-rospin-apps
```

Two runs start. Watch both, one after the other. Both must be green. Each run does: test, OIDC login, `docker build`, push to ACR. The last steps say the container app does not exist yet. This is only information: the run stays green.

**6c. Infrastructure, stage 2: create the Container Apps (about 3 min)**

```bash
gh variable set CREATE_WEB_APPS --body true --repo <github-user>/<team>-rospin-infra
gh workflow run terraform --repo <github-user>/<team>-rospin-infra
sleep 10
gh run watch --repo <github-user>/<team>-rospin-infra
```

Never set `CREATE_WEB_APPS` back to `false`: that would delete your apps. Read the URLs:

```bash
cd ~/rospin/<team>-rospin-infra/terraform/environments/dev
terraform output frontend_url
terraform output backend_url
```

If bootstrap said "Your Owner role is constrained" (`CI_CAN_ASSIGN_ROLES` is `false`): instead of the workflow, run `terraform apply` in the folder above. Read the plan, type `yes`, and wait about 3 minutes until you see `Apply complete!`.

Open the frontend URL. The first start can take 1 to 3 minutes. Until then the browser can show a 404 or an error: wait and refresh.

## Step 7 - MONITOR: is it healthy, and which version runs?

**You are here:** `~/rospin/<team>-rospin-infra/terraform/environments/dev`.

```bash
BACKEND=$(terraform output -raw backend_url)
FRONTEND=$(terraform output -raw frontend_url)
curl $BACKEND/health
curl $FRONTEND/version.txt
az extension add --name containerapp --only-show-errors
APP=$(terraform output -raw backend_webapp_name)
az containerapp logs show -g rg-rospin-<team>-dev -n $APP --tail 20
az containerapp revision list -g rg-rospin-<team>-dev -n $APP -o table
```

**Success:** `/health` prints `{"status":"ok", ... "version":"<git commit>"}` and `version.txt` prints the same commit. The log shows lines like `GET /health 200 OK`.

Azure also calls `/health` and `/healthz` all the time and restarts a container that fails. In the portal: Resource group, your container app, then *Log stream* and *Metrics*.

Try *Live* in the app. It reads real satellite images from the public AWS archive from inside your container (about 1 minute).

## Step 8 - ITERATE: change the app and watch it deploy

**You are here:** `~/rospin/<team>-rospin-apps`.

Ask your AI agent: *"Add a new region for my city."* It must add the region in `backend/app/regions.py` and create its sample data:

```bash
MSYS_NO_PATHCONV=1 docker compose run --rm -v "$PWD/backend/app:/app/app" backend python -m app.export_sample <region-id>
```

(About 1 minute, needs internet.) Without sample data the test fails and CI blocks the deploy: this is the safety net working.

No AI agent? Open `backend/app/regions.py` in a text editor, copy one `Region(...)` block, and change the id, name and numbers. Then run the command above with your new id.

Check what changed, then push:

```bash
git status
git diff
git add -A
git commit -m "feat(backend): add my city region"
git push
```

Before `git add -A`, `git status` must **not** list `terraform.tfvars`, `backend.hcl` or `bootstrap.env`. If it does, stop and ask your instructor.

Watch the run at `https://github.com/<github-user>/<team>-rospin-apps/actions`. After about 2 minutes `curl $BACKEND/health` shows your new commit. This is CI/CD: **commit -> test -> build -> push image -> deploy -> verify**.

Look at Terraform too:

```bash
cd ~/rospin/<team>-rospin-infra/terraform/environments/dev
terraform plan
```

`terraform plan` compares the code with Azure and changes nothing. After a deployment it can list small in-place updates on the two apps (`cooldown_period_in_seconds`, `polling_interval_in_seconds`, probe `transport`, `traffic_weight`). Azure does not send these default values back, so Terraform always sees a difference. They change nothing, and Terraform never touches the image.

## Step 9 - SUBMIT

Send your instructor one message with:

1. Team code and member names.
2. Link to your Apps repo and your Infra repo.
3. The live **frontend URL** and **backend URL** (`<backend_url>/docs`).
4. A link to one green *Actions* run of `terraform`, `backend` and `frontend` (copy the link from the address bar).
5. One sentence: what did your AI agent change?

## Step 10 - CLEAN UP (do it the same day)

The registry costs money every day. When you have sent step 9:

```bash
cd ~/rospin/<team>-rospin-infra
./scripts/cleanup.sh
```

It asks `yes` before each of three steps: delete the app resource group (stops the cost), delete the GitHub identity, delete the state storage. This deletes your app and cannot be undone. It takes about 5 minutes.

## Common problems

| Message or sign | Cause | Fix |
|---|---|---|
| `command not found: az` (or gh, terraform) | Tool not installed, or old terminal | Install it. Close Git Bash and open a new one. |
| `Cannot connect to the Docker daemon` or `pipe ... not found` | Docker Desktop is not running | Start Docker Desktop. Wait until it says running. |
| `port is already allocated` | Another program uses port 3000 or 8000 | Close it, or restart the PC. |
| `C:/Program Files/Git/...` inside an error | Git Bash changed a path | Put `MSYS_NO_PATHCONV=1` before the command. |
| `Permission denied` on `bootstrap.sh` | Script not executable | `chmod +x bootstrap/bootstrap.sh scripts/cleanup.sh` |
| `Not logged in to Azure` or `GitHub` | Login expired | `az login` or `gh auth login --scopes workflow` |
| `You are not Owner ...` | Wrong account or subscription | `az account list`, then select the Azure for Students ID. If it persists, ask your instructor. |
| Region blocked by policy | Student policy | Pick a region from the list the script prints. |
| `could not find any workflows named ...` | GitHub is not ready yet | Wait 30 seconds and run the command again. |
| `Image backend:latest not found` in the terraform run | Step 6b is not done or not green | Do 6b, wait for green, then 6c. |
| Azure login fails in Actions | You renamed a repository | Run `./bootstrap/bootstrap.sh` again. |
| App URL shows 404 or an error | The container is still starting | Wait 3 minutes and refresh. |
| Your repos are public and the logs show your subscription ID | Normal. The ID is not a secret and gives no access | If you prefer, make the repos private in the repository settings. |

On macOS with zsh, `#` starts a comment only after you run `setopt interactivecomments`. Copy only the part before `#`.
