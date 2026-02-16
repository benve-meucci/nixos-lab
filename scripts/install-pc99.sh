#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: ./install-pc99.sh [disk]" >&2
  echo "Example: ./install-pc99.sh /dev/sdb" >&2
  exit 1
fi

INSTALL_DISK="${1:-}"
FLAKE_REF="${FLAKE_REF:-github:giovantenne/nixos-lab}"
DISKO_URL="${DISKO_URL:-https://raw.githubusercontent.com/giovantenne/nixos-lab/master/disko-bios.nix}"

list_disks() {
  lsblk -dno PATH,SIZE,MODEL,TYPE | awk '$4=="disk" { printf "  %s  %s  %s\n", $1, $2, $3 }'
}

normalize_disk() {
  case "$1" in
    sda|/dev/sda)
      echo "/dev/sda"
      ;;
    sdb|/dev/sdb)
      echo "/dev/sdb"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Detect UEFI or BIOS
if [ -d /sys/firmware/efi ]; then
  echo "Error: UEFI boot not supported. Disable UEFI in BIOS settings." >&2
  exit 1
else
  echo "Detected BIOS boot"
fi

if [[ -z "$INSTALL_DISK" ]]; then
  echo "Available disks:"
  list_disks
  read -r -p "Choose install disk [/dev/sda or /dev/sdb]: " CHOSEN_DISK
  INSTALL_DISK=$(normalize_disk "$CHOSEN_DISK")
else
  INSTALL_DISK=$(normalize_disk "$INSTALL_DISK")
fi

if [[ -z "$INSTALL_DISK" ]]; then
  echo "Error: disk must be /dev/sda or /dev/sdb." >&2
  exit 1
fi

if [[ ! -b "$INSTALL_DISK" ]]; then
  echo "Error: disk '$INSTALL_DISK' not found." >&2
  exit 1
fi

echo "Selected disk: $INSTALL_DISK"
read -r -p "This will erase all data on $INSTALL_DISK. Type YES to continue: " CONFIRMATION
if [[ "$CONFIRMATION" != "YES" ]]; then
  echo "Installation cancelled."
  exit 1
fi

TEMP_DISKO_INPUT=$(mktemp)
TEMP_DISKO_FILE=$(mktemp)
trap 'rm -f "$TEMP_DISKO_INPUT" "$TEMP_DISKO_FILE"' EXIT

echo "Downloading disko config..."
curl -fsSL "$DISKO_URL" -o "$TEMP_DISKO_INPUT"
sed -E "s#device = \"/dev/sd[a-z]\";#device = \"${INSTALL_DISK}\";#" "$TEMP_DISKO_INPUT" > "$TEMP_DISKO_FILE"

echo "Partitioning disk..."
sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko "$TEMP_DISKO_FILE"

echo "Installing NixOS for pc99..."
sudo nixos-install --flake "${FLAKE_REF}#pc99" --no-write-lock-file --no-root-passwd

echo "Installation complete. Reboot with: reboot"
