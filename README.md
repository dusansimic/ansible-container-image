# ansible-container-image

Container image for running [Ansible](https://www.ansible.com/) playbooks in
CI/CD pipelines.

- **Base:** `python:3.14.1-slim`
- **Ansible:** community `ansible` package, major-pinned. Bundled majors: **14** (supported only).
- **Tooling:** `openssh-client`, `sshpass`, `git`, `rsync`
- **Registry:** `ghcr.io/<owner>/<repo>` (amd64)

## Usage

```bash
# Run a playbook (mount it at /ansible)
podman run --rm -v "$PWD:/ansible" ghcr.io/<owner>/<repo>:latest playbook.yml

# Pick a specific ansible major
podman run --rm -v "$PWD:/ansible" ghcr.io/<owner>/<repo>:latest-14 playbook.yml

# Other ansible tools (entrypoint is ansible-playbook by default)
podman run --rm --entrypoint ansible ghcr.io/<owner>/<repo>:latest --version
```

## Tags

| Tag | Meaning |
|-----|---------|
| `latest`, `main` | newest bundled major (14), last release / last main build |
| `latest-14` | last release of that ansible major |
| `main-14` | last `main`-branch build of that ansible major |
| `X.Y.Z`, `X.Y.Z-14` | repo release version |
| `14.1.0` | exact installed ansible version (immutable) |

## Development

See [AGENTS.md](AGENTS.md) for build, run, tagging, and maintenance procedures.
