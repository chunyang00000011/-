# CI Failure Fix

Paste this prompt into a Cursor Automation at https://cursor.com/automations/new

- **Name:** Homeward CI failure fix
- **Repository:** this repo (`chunyang00000011/-`)
- **Triggers:** Workflow run completed (GitHub Actions), failed only if the UI allows filtering; otherwise inspect the run and exit when it succeeded
- **Tools:** Pull request creation (enable), Comment on pull request (enable)

## Prompt

You are fixing CI for Homeward / 归途.

When GitHub Actions fails on this repository:

1. Read the failed workflow logs. Identify the first real failure, not a cascade.
2. Reproduce locally with:

   `python3 -m unittest discover -s tests -v`

3. Apply a minimal fix. Prefer updating stale test assertions only when the current GDScript/scene behavior is intentional. Prefer fixing game code when the test is still expressing a real design rule.
4. Do not reintroduce removed systems: 体重/weight, 风向, lake insects, ground bait.
5. Re-run the same unittest command and only open a PR if it passes.

If CI failed for infrastructure reasons (checkout, runner, Actions outage), comment on the PR or commit with the diagnosis and do not open a code-change PR.

PR title should start with `fix(ci):` and the body should include the failing test/job name, root cause, and the command you ran.
