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

for cmd in \
  parted \
  wipefs \
  partprobe \
  udevadm \
  mkfs.fat \
  mkfs.btrfs \
  btrfs \
  nixos-generate-config \
  nixos-install
do
  command -v "$cmd" >/dev/null || {
    echo "Required command not found: $cmd" >&2
    exit 1
  }
done

echo
echo "Installing '$HOST' to '$DISK'."
echo "ALL DATA ON THIS DISK WILL BE ERASED."
echo

lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS "$DISK"

echo
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 1

#
# Clean up an old installation target, if present.
#
sudo umount -R /mnt 2>/dev/null || true
sudo mkdir -p /mnt

#
# Partition layout:
#
#   partition 1: 1 GiB EFI
#   partition 2: remaining disk, Btrfs
#
# Runtime layout:
#
#   tmpfs             /
#   Btrfs /nix        /nix
#   Btrfs /home       /home
#   Btrfs /persist    /persist
#   vfat              /boot
#

sudo wipefs -af "$DISK"

sudo parted -s "$DISK" mklabel gpt

sudo parted -s "$DISK" \
  mkpart ESP fat32 1MiB 1025MiB

sudo parted -s "$DISK" \
  set 1 esp on

sudo parted -s "$DISK" \
  name 1 disk-main-ESP

sudo parted -s "$DISK" \
  mkpart system 1025MiB 100%

sudo parted -s "$DISK" \
  name 2 disk-main-system

sudo partprobe "$DISK"
sudo udevadm settle

#
# Resolve the actual partition devices without assuming whether this
# is /dev/sda, /dev/nvme0n1, etc.
#
ESP="$(
  lsblk -nrpo PATH,PARTLABEL "$DISK" |
    awk '$2 == "disk-main-ESP" { print $1; exit }'
)"

SYSTEM="$(
  lsblk -nrpo PATH,PARTLABEL "$DISK" |
    awk '$2 == "disk-main-system" { print $1; exit }'
)"

[[ -n "$ESP" && -b "$ESP" ]] || {
  echo "Could not locate the EFI partition." >&2
  exit 1
}

[[ -n "$SYSTEM" && -b "$SYSTEM" ]] || {
  echo "Could not locate the system partition." >&2
  exit 1
}

echo
echo "EFI partition:    $ESP"
echo "System partition: $SYSTEM"
echo

#
# Clear stale filesystem signatures from the new partitions.
#
sudo wipefs -af "$ESP"
sudo wipefs -af "$SYSTEM"

#
# Create filesystems.
#
sudo mkfs.fat -F 32 "$ESP"
sudo mkfs.btrfs -f "$SYSTEM"

#
# Temporarily mount the Btrfs top-level so we can create subvolumes.
#
sudo mkdir -p /mnt-btrfs
sudo mount "$SYSTEM" /mnt-btrfs

sudo btrfs subvolume create /mnt-btrfs/nix
sudo btrfs subvolume create /mnt-btrfs/home
sudo btrfs subvolume create /mnt-btrfs/persist

sudo umount /mnt-btrfs
sudo rmdir /mnt-btrfs

#
# The real root is tmpfs.
#
sudo mount \
  -t tmpfs \
  -o size=25%,mode=755 \
  none \
  /mnt

#
# Create mount points inside the ephemeral root.
#
sudo mkdir -p \
  /mnt/boot \
  /mnt/nix \
  /mnt/home \
  /mnt/persist

#
# Mount persistent Btrfs subvolumes.
#
sudo mount \
  -o subvol=/nix,compress=zstd,noatime \
  "$SYSTEM" \
  /mnt/nix

sudo mount \
  -o subvol=/home,compress=zstd,noatime \
  "$SYSTEM" \
  /mnt/home

sudo mount \
  -o subvol=/persist,compress=zstd,noatime \
  "$SYSTEM" \
  /mnt/persist

#
# Mount the EFI System Partition.
#
sudo mount \
  -o umask=0077 \
  "$ESP" \
  /mnt/boot

#
# Prepare persistent state expected by modules/impermanence.nix.
#
sudo mkdir -p \
  /mnt/persist/etc \
  /mnt/persist/var/lib/nixos

sudo install \
  -d \
  -m 700 \
  /mnt/persist/etc/NetworkManager/system-connections

#
# Generate a persistent machine-id.
#
sudo systemd-machine-id-setup \
  --root=/mnt/persist

#
# Copy this repository into persistent storage.
#
TARGET_CONFIG="/mnt/persist/etc/nixos"

sudo cp -aT \
  . \
  "$TARGET_CONFIG"

sudo rm -f "$TARGET_CONFIG/result"

#
# Generate the hardware configuration.
#
# Filesystems are deliberately excluded because the filesystem layout
# comes from disk-layout/uefi-impermanent.nix.
#
sudo mkdir -p \
  "$TARGET_CONFIG/hosts/$HOST"

sudo "$(command -v nixos-generate-config)" \
  --root /mnt \
  --no-filesystems \
  --show-hardware-config \
  | sudo tee \
      "$TARGET_CONFIG/hosts/$HOST/hardware-configuration.nix" \
      >/dev/null

#
# If the copied configuration is a Git repository, try to stage the
# generated hardware config.
#
# This matters because normal Git-backed flake evaluation ignores
# untracked files.
#
# Failure here is not fatal because nixos-install below uses path:.
#
if [[ -d "$TARGET_CONFIG/.git" ]]; then
  if ! git -C "$TARGET_CONFIG" \
    add "hosts/$HOST/hardware-configuration.nix"
  then
    echo >&2
    echo "WARNING: Could not stage the generated hardware configuration." >&2
    echo "After boot, run:" >&2
    echo >&2
    echo "  cd /etc/nixos" >&2
    echo "  git add hosts/$HOST/hardware-configuration.nix" >&2
    echo >&2
  fi
fi

#
# Create the immutable user's password hash.
#
tmp_hash="$(mktemp)"

cleanup() {
  rm -f "$tmp_hash"
}

trap cleanup EXIT

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

sudo install \
  -d \
  -m 700 \
  "$TARGET_CONFIG/secrets"

sudo install \
  -m 600 \
  -o root \
  -g root \
  "$tmp_hash" \
  "$TARGET_CONFIG/secrets/gustavo-password.hash"

#
# During nixos-install, make the persistent directories visible at
# the same locations they will have after boot.
#
# This ensures activation-time state is written to persistent storage
# rather than being lost with the installation tmpfs.
#
sudo mkdir -p \
  /mnt/etc/nixos \
  /mnt/var/lib/nixos \
  /mnt/etc/NetworkManager/system-connections

sudo mount \
  --bind \
  /mnt/persist/etc/nixos \
  /mnt/etc/nixos

sudo mount \
  --bind \
  /mnt/persist/var/lib/nixos \
  /mnt/var/lib/nixos

sudo mount \
  --bind \
  /mnt/persist/etc/NetworkManager/system-connections \
  /mnt/etc/NetworkManager/system-connections

#
# Also expose the persistent machine-id during installation.
#
sudo touch /mnt/etc/machine-id

sudo mount \
  --bind \
  /mnt/persist/etc/machine-id \
  /mnt/etc/machine-id

#
# Install NixOS.
#
# /mnt/nix is an actual persistent Btrfs subvolume, so the Nix store
# is written directly to disk instead of consuming space in the live
# installer's Nix store.
#
# path: is intentional: the freshly generated hardware configuration
# can be evaluated even if it has not been committed yet.
#
sudo nixos-install \
  --root /mnt \
  --flake "path:$TARGET_CONFIG#$HOST" \
  --no-channel-copy \
  --no-root-passwd

echo
echo "Installation complete."
echo
echo "Installed filesystem layout:"
echo
echo "  /         tmpfs"
echo "  /boot     vfat on $ESP"
echo "  /nix      Btrfs subvolume /nix"
echo "  /home     Btrfs subvolume /home"
echo "  /persist  Btrfs subvolume /persist"
echo
echo "Configuration:"
echo "  /persist/etc/nixos"
echo "  -> exposed as /etc/nixos by Impermanence"
echo
echo "Reboot when ready."
