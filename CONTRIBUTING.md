<img src="https://otgh-static-assets.s3.otgh.cloud/branding/logos/otgh_cloud_2024.png" alt="OTGH Cloud" width="200px" />

# Contributing

Thank you for your interest in contributing to this project.

You can help this project in multiple ways, whether it be by contributing new features and fixes, or raising issues for things that aren't working quite the way they should.

This document provides some general guidance before opening your first issue or pull request.

---

## Table of Contents

- [Repository Layout](#repository-layout)
- [Branching](#branching)
- [Development](#development)
- [Code Style](#code-style)
- [Commit Messages](#commit-messages)
- [Issues](#issues)
- [Pull Request Titles](#pull-request-titles)

---


## Code Style

- **Metadata**: `templates.json` is generated; CI validates it is well-formed and internally consistent.
- **Markdown**: Validated with `markdownlint-cli2` (config at `.github/rules/.markdownlint.jsonc`).

All linters run automatically on pull requests and where applicable the CI workflow applies and auto-commits fixes.

## Commit Messages

Individual commit messages within a PR follow the same prefix convention and
format as PR titles. Squash commits inherit the PR title, so keeping them
consistent is the most important thing.

## Issues

You can submit issues or enhancement requests [by visiting our issues page](https://github.com/otghcloud/proxmox-gha-manager-templates/issues).

## Pull Request Titles

Every pull request title **must** follow this format:

```text
<prefix>(<optional-scope>): <Description starting with a capital letter>
```

- The scope is optional and free-form (e.g. a template name or subsystem).
- A colon and a single space separate the prefix from the description.
- The description starts with a **capital letter**.
- The prefix and scope are **always lowercase**.
- **No trailing period.**

### Allowed Prefixes

| Prefix | When to use |
| --- | --- |
| `build:` | Build system, dependencies, or packaging |
| `chore:` | Maintenance tasks that do not fit any other category |
| `ci:` | Changes limited to GitHub Actions workflows or CI scripts |
| `docs:` | Documentation-only changes |
| `feat:` | A new user-facing feature or capability |
| `fix:` | Something was broken and is now corrected |
| `improve:` | An enhancement to existing behavior that is neither a bug fix nor a new feature |
| `refactor:` | Internal restructuring with no behavior change |
| `style:` | Cosmetic or formatting changes with no logic impact |
| `test:` | Test additions or corrections only |

### Examples

```text
feat(win25): Add the win25-vs2026 Proxmox template
fix(ubuntu-slim): Correct qemu-guest-agent install race condition
chore(runner-images): Bump vendored submodule to latest release
```

## Why This Matters

Following the conventions above helps keep our codebase tidy and readable.

Our release workflow depends on structured commit/pull request titles for accurately producing version numbers and release notes.

The CI process enforces these practices and will reject invalid submissions.

[core]: https://github.com/otghcloud/proxmox-gha-manager-core
[updater]: https://github.com/otghcloud/proxmox-gha-manager-templates-updater
[runner-images]: https://github.com/actions/runner-images
