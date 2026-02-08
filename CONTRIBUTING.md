# Contributing Guide (pro-dental)

This repository is maintained by a small team:
- Project Manager (PM): reviews PRs, manages Jira, approves merges
- Frontend Engineer (FE): Flutter UI
- Backend Engineer (BE): Node.js/Express API + DB

## 1) Workflow
1. Create a Jira ticket (e.g., PD-12).
2. Create a feature branch from `main`.
3. Commit with ticket reference.
4. Push branch and open a Pull Request (PR).
5. PR must be reviewed and approved before merging to `main`.

## 2) Branch Naming
Use one of the following:
- `feature/PD-<id>-short-title`
- `fix/PD-<id>-short-title`
- `chore/PD-<id>-short-title`

Examples:
- `feature/PD-11-booking-ui`
- `fix/PD-7-board-timezone`
- `chore/PD-5-precommit-hook`

## 3) Commit Message Convention
Format:
- `feat(PD-<id>): <message>`
- `fix(PD-<id>): <message>`
- `chore(PD-<id>): <message>`

Examples:
- `feat(PD-11): add date picker and time-slot buttons`
- `fix(PD-7): correct board time extraction`
- `chore(PD-5): add pre-commit lint hook`

## 4) Pull Request Rules
A PR must include:
- Jira ticket reference (PD-xx) in the title or description
- Short summary of changes
- How to test (steps)
- Screenshots for UI changes

## 5) Code Quality
Before pushing, run:
- Backend:
  - `npm run lint` (if available)
  - `npm test` (if available)
- Frontend:
  - `flutter analyze`
  - `flutter test` (if available)

## 6) Security Notes
- Do NOT commit secrets (tokens, passwords, production configs).
- Use `.env` and document required variables in README.
