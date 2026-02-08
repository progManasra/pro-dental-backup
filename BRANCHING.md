# Branching Strategy (Git + Jira) - pro-dental

We use a simple feature-branch workflow.

## Branches
- `main`: stable branch. Only merged via Pull Requests.
- Feature branches: one ticket per branch.

## Rules
1. Never commit directly to `main`.
2. Every change must be linked to a Jira ticket (PD-xx).
3. Small PRs are preferred (easy to review).
4. Use `git pull --rebase` to keep history clean.

## Daily Workflow (Developer)
```bash
git checkout main
git pull --rebase origin main
git checkout -b feature/PD-xx-short-title
