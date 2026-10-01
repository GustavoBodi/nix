# NixOS installation

Boot the NixOS installer ISO and connect to the internet.

> **Warning:** the selected disk is erased completely.

## 1. Clone the configuration

```bash
git clone <REPO_URL> /tmp/nixos
cd /tmp/nixos
```

Choose a hostname and identify the target disk:

```bash
HOST=laptop
lsblk -o NAME,SIZE,MODEL,SERIAL
ls -l /dev/disk/by-id/
DISK=/dev/disk/by-id/<YOUR-DISK>
```

## 2. Add this machine

```bash
mkdir -p hosts/$HOST

nixos-generate-config \
  --no-filesystems \
  --show-hardware-config \
  > hosts/$HOST/hardware-configuration.nix

git add hosts/$HOST/hardware-configuration.nix
```

No `default.nix` or `extra.nix` is needed unless this machine has host-specific configuration.

## 3. Create the local password secret

```bash
install -d -m 700 /tmp/secrets
umask 077
nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt \
  > /tmp/secrets/gustavo-password.hash
```

## 4. Validate

```bash
nix flake check
```

## 5. Install

```bash
sudo nix run .#disko-install -- \
  --write-efi-boot-entries \
  --flake .#$HOST \
  --disk main "$DISK" \
  --extra-files . etc/nixos \
  --extra-files /tmp/secrets etc/nixos/secrets
```

This creates a GPT disk with a 1 GiB EFI partition and uses the rest as ext4 `/`.

## 6. Reboot

```bash
reboot
```

After booting the new system, commit and push its generated hardware configuration:

```bash
cd /etc/nixos
git add hosts/$HOST/hardware-configuration.nix
git commit -m "Add $HOST"
git push
```
