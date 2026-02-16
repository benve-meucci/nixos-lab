#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: ./setup.sh <pc-number> [disk]" >&2
  echo "Example: ./setup.sh 5 /dev/sdb" >&2
  exit 1
fi

PC_NUMBER="$1"
INSTALL_DISK="${2:-}"

if ! [[ "$PC_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Error: PC number must be numeric." >&2
  exit 1
fi

if [[ "$PC_NUMBER" -lt 1 || "$PC_NUMBER" -gt 30 ]]; then
  echo "Error: PC number must be between 1 and 30." >&2
  exit 1
fi

PC_ID=$(printf "%02d" "$PC_NUMBER")
PC_NAME="pc${PC_ID}"

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

# Extract settings from flake.nix
MASTER_IP=$(awk -F'"' '/masterDhcpIp =/ { print $2; exit }' flake.nix)
CACHE_KEY=$(awk -F'"' '/cachePublicKey =/ { print $2; exit }' flake.nix)

if [[ -z "$MASTER_IP" || "$MASTER_IP" == "MASTER_DHCP_IP" ]]; then
  echo "Error: masterDhcpIp not configured in flake.nix" >&2
  exit 1
fi

echo "Using binary cache at ${MASTER_IP}:5000"

# Detect UEFI or BIOS
if [ -d /sys/firmware/efi ]; then
  echo "Error: UEFI boot not supported. Disable UEFI in BIOS settings." >&2
  exit 1
else
  echo "Detected BIOS boot"
fi

TEMP_DISKO_FILE=$(mktemp)
trap 'rm -f "$TEMP_DISKO_FILE"' EXIT
sed -E "s#device = \"/dev/sd[a-z]\";#device = \"${INSTALL_DISK}\";#" ./disko-bios.nix > "$TEMP_DISKO_FILE"

echo "Partitioning disk..."
sudo disko --mode disko "$TEMP_DISKO_FILE"

echo "Installing NixOS for ${PC_NAME}..."
sudo nixos-install --flake ".#${PC_NAME}" \
  --option substituters "http://${MASTER_IP}:5000" \
  --option trusted-public-keys "${CACHE_KEY}" \
  --no-channel-copy \
  --no-root-passwd
