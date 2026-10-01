#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <hostname> <disk>}"
DISK="${2:?Usage: $0 <hostname> <disk>}"

cd "$(dirname "$0")"

[[ -b "$DISK" ]] || {
  echo "Not a block device: $DISK" >&2
  exit 1
}

[[ "$HOST" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || {
  echo "Invalid hostname: $HOST" >&2
  exit 1
}

[[ -d /sys/firmware/efi ]] || {
  echo "Boot the installer in UEFI mode." >&2
  exit 1
}

echo "Installing '$HOST' to '$DISK'. ALL DATA ON THIS DISK WILL BE ERASED."
lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS "$DISK"
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 1

# Partition: 1 GiB EFI + remaining space as ext4 root.
sudo umount -R /mnt 2>/dev/null || true
sudo wipefs -af "$DISK"
sudo parted -s "$DISK" mklabel gpt
sudo parted -s "$DISK" mkpart ESP fat32 1MiB 1025MiB
sudo parted -s "$DISK" set 1 esp on
sudo parted -s "$DISK" name 1 disk-main-ESP
sudo parted -s "$DISK" mkpart root ext4 1025MiB 100%
sudo parted -s "$DISK" name 2 disk-main-root
sudo partprobe "$DISK"
sudo udevadm settle

ESP=/dev/disk/by-partlabel/disk-main-ESP
ROOT=/dev/disk/by-partlabel/disk-main-root

sudo mkfs.fat -F 32 "$ESP"
sudo mkfs.ext4 -F "$ROOT"

sudo mount "$ROOT" /mnt
sudo mkdir -p /mnt/boot
sudo mount -o umask=0077 "$ESP" /mnt/boot

# Copy the repository to the target system.
sudo mkdir -p /mnt/etc/nixos
sudo cp -a . /mnt/etc/nixos/
sudo rm -f /mnt/etc/nixos/result

# Hardware only; the existing disk-layout module supplies / and /boot.
sudo mkdir -p "/mnt/etc/nixos/hosts/$HOST"
nixos-generate-config \
  --root /mnt \
  --no-filesystems \
  --show-hardware-config \
  | sudo tee "/mnt/etc/nixos/hosts/$HOST/hardware-configuration.nix" >/dev/null

# Create the immutable user's password hash.
tmp_hash="$(mktemp)"
trap 'rm -f "$tmp_hash"' EXIT
umask 077

if command -v mkpasswd >/dev/null; then
  mkpasswd -m yescrypt > "$tmp_hash"
else
  nix \
    --extra-experimental-features "nix-command flakes" \
    shell nixpkgs#mkpasswd \
    -c mkpasswd -m yescrypt \
    > "$tmp_hash"
fi

sudo install -d -m 700 /mnt/etc/nixos/secrets
sudo install -m 600 -o root -g root \
  "$tmp_hash" \
  /mnt/etc/nixos/secrets/gustavo-password.hash

# nixos-install builds directly into /mnt/nix/store, avoiding the live ISO store.
sudo nixos-install \
  --root /mnt \
  --flake "path:/mnt/etc/nixos#$HOST" \
  --no-channel-copy \
  --no-root-passwd

echo
echo "Installation complete. Reboot when ready."

