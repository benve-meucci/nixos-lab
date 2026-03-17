#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: ./scripts/shutdown-lab.sh [--yes]" >&2
  exit 1
fi

AUTO_CONFIRM="false"

if [[ $# -eq 1 ]]; then
  case "$1" in
    --yes)
      AUTO_CONFIRM="true"
      ;;
    *)
      echo "Error: unsupported argument '$1'." >&2
      echo "Usage: ./scripts/shutdown-lab.sh [--yes]" >&2
      exit 1
      ;;
  esac
fi

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LOCAL_HOSTNAME=$(hostname -s)
COLMENA_CMD=(
  nix
  --extra-experimental-features
  "nix-command flakes"
  run
  nixpkgs#colmena
  --
)

# shellcheck source=/home/admin/nixos-lab/scripts/lib/lab-meta.sh
source "${REPO_ROOT}/scripts/lib/lab-meta.sh"
load_lab_meta "${REPO_ROOT}"

if [[ "${LOCAL_HOSTNAME}" != "${LAB_CONTROLLER_NAME}" ]]; then
  echo "Error: this script must run on ${LAB_CONTROLLER_NAME}, current host is ${LOCAL_HOSTNAME}." >&2
  exit 1
fi

if [[ "${AUTO_CONFIRM}" != "true" ]]; then
  read -r -p "Spegnere tutti i client del gruppo @lab e poi ${LAB_CONTROLLER_NAME}? [y/N] " CONFIRMATION
  if [[ "${CONFIRMATION}" != "y" && "${CONFIRMATION}" != "Y" ]]; then
    echo "Operazione annullata."
    exit 0
  fi
fi

echo "Invio shutdown ai client del gruppo @lab..."
(
  cd "${REPO_ROOT}"
  "${COLMENA_CMD[@]}" exec --impure --on @lab systemctl poweroff
)

echo "Client arrestati. Spengo ${LAB_CONTROLLER_NAME}..."
systemctl poweroff
