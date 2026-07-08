ARG PYTHON_TAG=3.14.1-slim
FROM python:${PYTHON_TAG}

# Ansible community-package major to pin (must be a supported, non-EOL major).
# Latest patch floats within the major.
ARG ANSIBLE_MAJOR=14

# SSH + git essentials for running playbooks against remote hosts.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-client sshpass git rsync \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "ansible~=${ANSIBLE_MAJOR}.0"

WORKDIR /ansible

# Build-time smoke test: fail the build if ansible is broken.
RUN ansible --version

ENTRYPOINT ["ansible-playbook"]
