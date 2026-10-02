#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: $0 <hostname> <disk>}"
DISK="${2:?Usage: $0 <hostname> <disk>}"

cd "$(dirname "$0")"

MAPPER_NAME="cryptroot"
MAPPER="/dev/mapper/$MAPPER_NAME"

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

command -v cryptsetup >/dev/null || {
  echo "cryptsetup is required." >&2
  exit 1
}

if [[ -e "$MAPPER" ]]; then
  echo "$MAPPER already exists." >&2
  echo "Close the existing mapping before running this installer." >&2
  exit 1
fi

echo
echo "Installing '$HOST' to '$DISK'."
echo "ALL DATA ON THIS DISK WILL BE ERASED."
echo

lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS "$DISK"

echo
read -r -p "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 1

#
# Clean up any previous target mounted at /mnt.
#
sudo umount -R /mnt 2>/dev/null || true
sudo mkdir -p /mnt

#
# Partition layout:
#
#   1 GiB EFI System Partition
#   remaining disk -> LUKS2 -> ext4 -> /persist
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
# Resolve the actual partition device names without assuming
# /dev/sda1 versus /dev/nvme0n1p1.
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
  echo "Could not find EFI partition." >&2
  exit 1
}

[[ -n "$SYSTEM" && -b "$SYSTEM" ]] || {
  echo "Could not find system partition." >&2
  exit 1
}

echo
echo "EFI partition:    $ESP"
echo "System partition: $SYSTEM"
echo

#
# Remove any stale filesystem signatures from the newly-created
# partitions.
#
sudo wipefs -af "$ESP"
sudo wipefs -af "$SYSTEM"

#
# EFI filesystem.
#
sudo mkfs.fat -F 32 "$ESP"

#
# Encrypt the persistent system partition.
#
# cryptsetup will ask for the LUKS passphrase here.
#
echo
echo "Creating LUKS2 encrypted system volume..."
echo

sudo cryptsetup luksFormat \
  --type luks2 \
  "$SYSTEM"

echo
echo "Opening encrypted system volume..."
echo

sudo cryptsetup open \
  "$SYSTEM" \
  "$MAPPER_NAME"

#
# Persistent filesystem.
#
sudo mkfs.ext4 \
  -F \
  -L persist \
  "$MAPPER"

#
# The installed machine's real root is tmpfs.
#
# This mirrors:
#
#   fileSystems."/" = {
#     fsType = "tmpfs";
#     options = [ "defaults" "size=25%" "mode=755" ];
#   };
#
sudo mount \
  -t tmpfs \
  -o size=25%,mode=755 \
  tmpfs \
  /mnt

#
# Persistent backing filesystem.
#
sudo mkdir -p /mnt/persist

sudo mount \
  "$MAPPER" \
  /mnt/persist

#
# Persistent /nix and /home.
#
# At runtime these are bind-mounted from:
#
#   /persist/nix  -> /nix
#   /persist/home -> /home
#
sudo mkdir -p \
  /mnt/persist/nix \
  /mnt/persist/home \
  /mnt/nix \
  /mnt/home

sudo mount \
  --bind \
  /mnt/persist/nix \
  /mnt/nix

sudo mount \
  --bind \
  /mnt/persist/home \
  /mnt/home

#
# EFI System Partition.
#
sudo mkdir -p /mnt/boot

sudo mount \
  -o umask=0077 \
  "$ESP" \
  /mnt/boot

#
# Prepare persistent system state expected by the Impermanence
# configuration.
#
sudo mkdir -p \
  /mnt/persist/etc \
  /mnt/persist/var/lib/nixos

sudo install \
  -d \
  -m 700 \
  /mnt/persist/etc/NetworkManager/system-connections

#
# Generate a permanent machine-id directly in persistent storage.
#
# Impermanence later exposes this as /etc/machine-id.
#
sudo systemd-machine-id-setup \
  --root=/mnt/persist

#
# Copy the configuration repository to persistent storage.
#
# /etc/nixos itself lives on the ephemeral root and will later be
# supplied by:
#
#   environment.persistence."/persist"
#
TARGET_CONFIG="/mnt/persist/etc/nixos"

sudo cp -a \
  . \
  "$TARGET_CONFIG"

sudo rm -f \
  "$TARGET_CONFIG/result"

#
# Generate hardware-specific configuration.
#
# Filesystems deliberately aren't generated here; the filesystem
# topology is supplied declaratively by the NixOS configuration.
#
sudo mkdir -p \
  "$TARGET_CONFIG/hosts/$HOST"

nixos-generate-config \
  --root /mnt \
  --no-filesystems \
  --show-hardware-config \
  | sudo tee \
      "$TARGET_CONFIG/hosts/$HOST/hardware-configuration.nix" \
      >/dev/null

#
# If this is a Git-backed flake, make sure a newly-created host
# hardware configuration is visible to future normal Git-flake
# evaluations.
#
#
# Do NOT add the password hash below to Git.
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
# The NixOS configuration reads:
#
#   /persist/etc/nixos/secrets/gustavo-password.hash
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
# Install directly into /mnt/nix/store.
#
# Because /mnt/nix is a bind mount of /mnt/persist/nix,
# the Nix store goes directly to persistent storage instead
# of filling the live installer ISO's store.
#
# Using path: is intentional: it includes the freshly-generated
# hardware configuration even if it has not yet been committed.
#
sudo nixos-install \
  --root /mnt \
  --flake "path:$TARGET_CONFIG#$HOST" \
  --no-channel-copy \
  --no-root-passwd

echo
echo "Installation complete."
echo
echo "Installed layout:"
echo
echo "  /         tmpfs"
echo "  /boot     $ESP"
echo "  /persist  $MAPPER"
echo "  /nix      /persist/nix"
echo "  /home     /persist/home"
echo
echo "The persistent system partition is protected by LUKS2."
echo
echo "Reboot when ready."
