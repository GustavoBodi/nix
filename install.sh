#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <hostname> <disk>}"
DISK="${2:?Usage: $0 <hostname> <disk>}"

cd "$(dirname "$0")"

[[ -b "$DISK" ]] || { echo "Not a block device: $DISK" >&2; exit 1; }
[[ "$HOST" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || {
  echo "Invalid hostname: $HOST" >&2
  exit 1
}

echo "Installing '$HOST' to '$DISK' (ALL DATA ON THIS DISK WILL BE ERASED)"
lsblk "$DISK"
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 1

mkdir -p "hosts/$HOST"
nixos-generate-config --no-filesystems --show-hardware-config \
  > "hosts/$HOST/hardware-configuration.nix"

secrets="$(mktemp -d)"
trap 'rm -rf "$secrets"' EXIT
umask 077

if command -v mkpasswd >/dev/null; then
  mkpasswd -m yescrypt > "$secrets/gustavo-password.hash"
else
  nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt \
    > "$secrets/gustavo-password.hash"
fi

sudo nix run 'path:.#disko-install' -- \
  --write-efi-boot-entries \
  --flake "path:.#$HOST" \
  --disk main "$DISK" \
  --extra-files . etc/nixos \
  --extra-files "$secrets" etc/nixos/secrets

echo "Install complete. Reboot when ready."

