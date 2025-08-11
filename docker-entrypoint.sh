#!/usr/bin/env bash
set -euo pipefail

export PYENV_ROOT="/root/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# initialize pyenv in this shell so `pyenv activate` works
if command -v pyenv >/dev/null 2>&1; then
  # load pyenv functions
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  # try to activate the virtualenv created during build
  VENV_NAME="${PYENV_VENV_NAME:-env-system}"
  if pyenv versions --bare | grep -qx "$VENV_NAME"; then
    pyenv activate "$VENV_NAME"
  fi
fi

# exec the user's command (default: bash -l)
exec "$@"
