#!/usr/bin/env bash
# Run as the dedicated empire user after configure_agent_worker_poc.yml.
set -euo pipefail
[[ "$(id -un)" == empire ]] || { echo 'Run this as empire' >&2; exit 1; }
umask 077
EMPIRE_T3_VERSION="${EMPIRE_T3_VERSION:-0.1.2}"
mkdir -p ~/.local/bin ~/.ssh ~/GIT/EMPIRE
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -q -t ed25519 -N '' -C empire-worker-poc -f ~/.ssh/id_ed25519
fi
chmod 700 ~/.ssh
if [[ ! -x ~/.local/bin/t3 ]]; then
  curl -fsSL https://t3.codes/install.sh -o /tmp/empire-t3-install.sh
  sh /tmp/empire-t3-install.sh
fi
# Keep reruns aligned with the scoped-pairing version used by this worker.
# `t3 update` can switch the installed binary before failing to restart the
# user service in a non-login shell; service install below then updates the
# unit and restarts it through the user's active systemd manager.
if [[ "$(~/.local/bin/t3 --version)" != "t3 v${EMPIRE_T3_VERSION}" ]]; then
  if ! ~/.local/bin/t3 update "$EMPIRE_T3_VERSION" --channel stable --yes; then
    [[ "$(~/.local/bin/t3 --version)" == "t3 v${EMPIRE_T3_VERSION}" ]] || exit 1
  fi
fi
if [[ ! -x ~/.local/bin/kubectl ]]; then
  version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  task_dir=$(mktemp -d)
  trap 'rm -rf "$task_dir"' EXIT
  curl -fsSL "https://dl.k8s.io/release/${version}/bin/linux/arm64/kubectl" -o "$task_dir/kubectl"
  curl -fsSL "https://dl.k8s.io/release/${version}/bin/linux/arm64/kubectl.sha256" -o "$task_dir/kubectl.sha256"
  (cd "$task_dir" && printf '%s  kubectl\n' "$(cat kubectl.sha256)" | sha256sum --check)
  install -m 0755 "$task_dir/kubectl" ~/.local/bin/kubectl
fi
if [[ ! -x ~/.local/bin/codex ]]; then
  npm install --prefix ~/.local @openai/codex@0.159.3
  ln -sfn /home/empire/.local/node_modules/.bin/codex ~/.local/bin/codex
fi
mkdir -p ~/.config/empire
chmod 700 ~/.config/empire
export PATH="$HOME/.local/bin:$PATH"
mkdir -p ~/.t3
# Service setup may print pairing details: retain them privately on the worker.
t3 service install > ~/.t3/service-install.private.log 2>&1
mkdir -p ~/.config/systemd/user/t3code.service.d
cat > ~/.config/systemd/user/t3code.service.d/worker.conf <<'UNIT'
[Service]
Environment=PATH=/home/empire/.local/bin:/usr/local/bin:/usr/bin:/bin
Environment=EMPIRE_ROOT=/home/empire/GIT/EMPIRE
Environment=EMPIRE_GIT_ROOT=/home/empire/GIT
Environment=EMPIRE_ENV_FILE=
Environment=EMPIRECTL_TMP_ROOT=/tmp
WorkingDirectory=/home/empire/GIT/EMPIRE/control
UNIT
cat > ~/.config/systemd/user/t3code.service.d/credentials.conf <<'UNIT'
[Service]
EnvironmentFile=-/home/empire/.config/empire/credentials.env
UNIT
systemctl --user daemon-reload
systemctl --user restart t3code.service
t3 --version
kubectl version --client
op --version
ansible --version | head -1
aws --version
