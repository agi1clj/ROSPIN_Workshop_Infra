# AI from day one

Both repositories ship `AGENTS.md`: the open standard that Claude Code, Codex, Copilot, Cursor and others read. `CLAUDE.md` and `GEMINI.md` only import it (`@AGENTS.md`), so there is one source of truth.

| Agent | Reads | Skills setup |
|---|---|---|
| Claude Code | `CLAUDE.md` -> `AGENTS.md` | Offers the plugins from `.claude/settings.json` when you trust the folder |
| Gemini CLI | `GEMINI.md` -> `AGENTS.md` | Commands below |
| Codex, Copilot, Cursor | `AGENTS.md` | Commands below |

## Skills used in this workshop

```bash
npx skills add hashicorp/agent-skills/plugins/terraform/skills/terraform-style-guide
npx skills add hashicorp/agent-skills/plugins/terraform/skills/terraform-test
npx skills add https://github.com/antonbabenko/terraform-skill
npx skills add microsoft/azure-skills
```

- `terraform-style-guide`: HashiCorp formatting and structure rules for `.tf` files.
- `terraform-test`: writes `terraform test` files like `tests/plan.tftest.hcl`.
- `terraform-skill`: module, testing and CI patterns.
- `azure-skills`: `azure-validate` (check before you deploy), `azure-diagnostics` (debug a failing app), `azure-deploy`.

## Good habits

- Tell the agent the goal and the rule: *"Follow AGENTS.md. Run the checks before you finish."*
- Read every diff. You own the commit.
- Never paste secrets into a prompt. This project has none: Azure access uses OIDC.
- Agents must not run `terraform apply` or `bootstrap.sh` without your OK. `AGENTS.md` says so.
