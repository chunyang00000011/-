# Cursor Automations

GitHub Actions CI is in `.github/workflows/ci.yml` and runs on every push and pull request.

Cursor Automations cannot be created from the repository. Create them once in the dashboard:

1. Open [cursor.com/automations/new](https://cursor.com/automations/new)
2. Connect this GitHub repository
3. Copy a prompt file from this folder
4. Set the triggers and tools listed at the top of that file
5. Save and enable the automation

| File | When it runs | What it does |
| --- | --- | --- |
| `pr-review.md` | PR opened or updated | Reviews gameplay/script diffs and comments |
| `ci-failure-fix.md` | GitHub Actions failed | Reproduces the failure and opens a fix PR |

Optional dashboard agents on [cursor.com/automations](https://cursor.com/automations): Bugbot for extra PR review, Security Agents for vulnerability scans.
