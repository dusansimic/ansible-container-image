# Ansible CI/CD Container Image — Developer & Maintenance Guide

## Overview
Container image for **running Ansible playbooks** in CI/CD (GitHub Actions).

- Base: pinned `python:3.14.1-slim`.
- Ansible: community `ansible` package, **major-pinned**. Bundled majors are
  built as matrix variants (currently **14**).
- Baked tooling: `openssh-client`, `sshpass`, `git`, `rsync`.
- Entrypoint: `ansible-playbook` (`WORKDIR /ansible`).
- Registry: `ghcr.io/<owner>/<repo>`. Built with **buildah**, amd64 only.

## Support policy
- **Only build supported, non-EOL releases.** Never bundle an ansible major or a
  Python minor that has reached end-of-life.
- **Ansible:** track only actively-maintained community majors. When a major goes
  EOL, remove it from the matrix (see *Adding / rotating an ansible major*).
  Check status at <https://endoflife.date/ansible>.
- **Python:** track only an actively-supported release (prefer the latest stable).
  Bump `PYTHON_TAG` when the tracked minor nears EOL or a newer stable is adopted.
  Check status at <https://endoflife.date/python>.

## Local build
Pass the ansible major via build-arg (one image per major):

```bash
buildah bud --build-arg ANSIBLE_MAJOR=14 -t ansible:14 .
```

`podman` works identically (`podman build --build-arg ...`). Override the base
with `--build-arg PYTHON_TAG=<tag>` if needed.

## Run a playbook
Mount the playbook dir at `/ansible`:

```bash
podman run --rm -v "$PWD:/ansible" ghcr.io/<owner>/<repo>:latest playbook.yml
```

Override the entrypoint for other tools:

```bash
podman run --rm --entrypoint ansible        ansible:14 --version
podman run --rm --entrypoint ansible-galaxy ansible:14 collection list
podman run --rm --entrypoint sh -it         ansible:14
```

For SSH to managed hosts, mount keys / agent socket as usual
(`-v ~/.ssh:/root/.ssh:ro` or forward `SSH_AUTH_SOCK`).

On SELinux hosts (Fedora/RHEL), append `:Z` to bind mounts so the container can
read them: `-v "$PWD:/ansible:Z"`.

## Smoke checks
```bash
podman run --rm --entrypoint ansible ansible:14 --version      # ansible-core version
podman run --rm ansible:14 --version                            # via ansible-playbook entrypoint
podman run --rm --entrypoint pip ansible:14 show ansible        # community pkg version (tag source)
podman run --rm --entrypoint sh  ansible:14 -c 'for c in ssh sshpass git rsync; do command -v "$c"; done'
```

## Tag scheme
Repo `ghcr.io/<owner>/<repo>`. The newest bundled major
(`LATEST_ANSIBLE_MAJOR`, currently `14`) additionally gets the unsuffixed
"plain" tag of each kind.

| Event | ansible 14 (newest) |
|-------|---------------------|
| push to `main` | `main-14`, `main` |
| release `vX.Y.Z` | `X.Y.Z-14`, `latest-14`, `<full14>`, `X.Y.Z`, `latest` |

- `<full>` = exact installed community version (e.g. `14.1.0`), immutable, release-only.
- Plain `main` / `latest` / `X.Y.Z` always track the newest bundled major.
- When more than one major is bundled, each also gets `-<major>`-suffixed tags.

## Releasing
- Push to `main` → publishes `main-*` tags (and plain `main`).
- Push a git tag `vX.Y.Z` → publishes versioned + `latest*` + immutable full-version tags.
- No commit-sha tags. No push on PRs.

## Adding / rotating an ansible major
Edit `.github/workflows/build.yml`:
1. Update `matrix.ansible_major` (add/remove majors).
2. Set `LATEST_ANSIBLE_MAJOR` to the newest major in the matrix.

## Bumping base / handling drift
- Base bump: change `PYTHON_TAG` — both the `Containerfile` default **and** the
  workflow `env.PYTHON_TAG`.
- Ansible patch floats within the pinned major on each rebuild (`ansible~=<major>.0`).
  Pin tighter in the `Containerfile` if strict reproducibility is required.
- Rebuild (re-push `main` / re-tag) to pick up base-image CVE patches.

## CI
`.github/workflows/build.yml`: matrix build over ansible majors with buildah,
GHCR auth via the built-in `GITHUB_TOKEN` (needs `packages: write`). buildah and
podman are preinstalled on `ubuntu-latest`. `fail-fast: false` keeps one major's
failure from cancelling the others.
