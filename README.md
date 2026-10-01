# NixOS installation runbook

This repository is the source of truth for the machine.

The installation model is intentionally simple:

- `flake.lock` pins Nixpkgs and Home Manager.
- `configuration.nix` contains the shared system configuration.
- `home/gustavo.nix` contains the shared user environment.
- `hosts/<hostname>/default.nix` contains machine-specific settings.
- `hosts/<hostname>/hardware-configuration.nix` is generated once on the target machine.
- `/etc/nixos/secrets/gustavo-password.hash` is created locally on each machine and is **not** committed to Git.

The commands below assume the current repository layout uses the `mkHost` helper and a host set similar to:

```nix
hosts = {
  nixos = mkHost "nixos";
};
```

## 1. Boot the NixOS installer

Boot the current NixOS graphical or minimal ISO in UEFI mode.

Connect to the network. On the graphical ISO, NetworkManager can be configured normally. From a terminal:

```bash
nmtui
```

Verify connectivity:

```bash
ping -c 3 nixos.org
```

## 2. Partition, format and mount the target disk

This is deliberately not automated by this repository because it is destructive and can differ between machines.

Create the desired disk layout, then mount the installed system under `/mnt`.

For a normal UEFI installation the end result should look conceptually like:

```text
/mnt       -> root filesystem
/mnt/boot  -> EFI System Partition
```

For a laptop or any machine containing sensitive data, prefer LUKS encryption for the root filesystem.

Before continuing, verify the mounts:

```bash
findmnt /mnt
findmnt /mnt/boot
```

Do **not** continue until these point at the intended target disk.

## 3. Become root and define the installation variables

```bash
sudo -i
```

Set the repository URL and the new machine hostname:

```bash
export REPO_URL='<REPO_URL>'
export HOST='laptop'
```

Example:

```bash
export REPO_URL='https://github.com/your-user/nixos-config.git'
export HOST='laptop'
```

Use a simple hostname containing letters, digits and hyphens.

## 4. Generate the target machine hardware configuration

Generate into a temporary directory so the repository is not overwritten:

```bash
rm -rf /tmp/nixos-generated
nixos-generate-config --root /mnt --dir /tmp/nixos-generated
```

Inspect the generated hardware configuration if desired:

```bash
less /tmp/nixos-generated/hardware-configuration.nix
```

The important file is:

```text
/tmp/nixos-generated/hardware-configuration.nix
```

Do not use the generated `configuration.nix`; the repository already provides the real system configuration.

## 5. Clone the configuration directly into the installed system

Make sure `/mnt/etc/nixos` is not holding generated files that would conflict with the repository:

```bash
rm -rf /mnt/etc/nixos
```

Clone the repository:

```bash
git clone "$REPO_URL" /mnt/etc/nixos
cd /mnt/etc/nixos
```

The clone contains the exact `flake.lock` that was tested on the existing machine.

Do **not** run `nix flake update` during installation.

## 6. Create the new host

Create its host directory:

```bash
mkdir -p "hosts/$HOST"
```

Install the generated hardware configuration:

```bash
cp /tmp/nixos-generated/hardware-configuration.nix \
  "hosts/$HOST/hardware-configuration.nix"
```

Create a minimal host module:

```bash
cat > "hosts/$HOST/default.nix" <<EOF
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "$HOST";
}
EOF
```

This minimal host module is appropriate when the machine does not require extra host-specific configuration.

### NVIDIA machines

Before installing, check the graphics hardware:

```bash
lspci -nn | grep -Ei 'VGA|3D|Display'
```

If the machine has NVIDIA graphics, especially hybrid Intel/AMD + NVIDIA graphics, do **not** blindly reuse the minimal host module. Add the appropriate NVIDIA configuration to `hosts/$HOST/default.nix`.

The existing desktop host can be used as a reference:

```bash
cat hosts/nixos/default.nix
```

Do not copy desktop-specific monitor/Kanshi settings to a laptop unless they are actually appropriate for that machine.

## 7. Add the new host to the flake

The current flake has a host set similar to:

```nix
hosts = {
  nixos = mkHost "nixos";
};
```

Add the new host automatically after the existing `nixos` entry:

```bash
if ! grep -q "${HOST} = mkHost \"${HOST}\";" flake.nix; then
  sed -i \
    "/nixos = mkHost \"nixos\";/a\\        ${HOST} = mkHost \"${HOST}\";" \
    flake.nix
fi
```

Verify:

```bash
grep -A10 'hosts = {' flake.nix
```

You should see both machines, for example:

```nix
hosts = {
  nixos = mkHost "nixos";
  laptop = mkHost "laptop";
};
```

## 8. Stage the new host for flake evaluation

Because the configuration is a Git flake, newly created files must be tracked before Nix can see them.

Stage only the declarative configuration:

```bash
git add \
  flake.nix \
  "hosts/$HOST/default.nix" \
  "hosts/$HOST/hardware-configuration.nix"
```

Check:

```bash
git status --short
```

The password file created in the next step must remain untracked.

## 9. Create Gustavo's password hash locally

The system configuration expects:

```text
/etc/nixos/secrets/gustavo-password.hash
```

On the target filesystem this is:

```text
/mnt/etc/nixos/secrets/gustavo-password.hash
```

Create it with restrictive permissions:

```bash
install -d -m 700 /mnt/etc/nixos/secrets
umask 077
mkpasswd -m yescrypt > /mnt/etc/nixos/secrets/gustavo-password.hash
chmod 600 /mnt/etc/nixos/secrets/gustavo-password.hash
chown root:root /mnt/etc/nixos/secrets/gustavo-password.hash
```

`mkpasswd` will prompt for the password.

Verify that the file contains exactly one hash line without printing the hash itself:

```bash
test "$(wc -l < /mnt/etc/nixos/secrets/gustavo-password.hash)" -eq 1 \
  && echo 'password hash: OK'
```

Do not run `git add` on this file.

The repository `.gitignore` should exclude `secrets/`.

## 10. Validate the complete repository

First verify the new host exists as a flake configuration:

```bash
nix flake show
```

Then run the repository checks:

```bash
nix flake check
```

The repository is configured so that the checks build every declared NixOS host. This means the existing desktop and the new machine must both evaluate and build successfully before continuing.

If this fails, fix the configuration before installing.

## 11. Build the exact new machine configuration explicitly

Even after `nix flake check`, build the target host directly:

```bash
nix build \
  ".#nixosConfigurations.${HOST}.config.system.build.toplevel" \
  --no-link
```

This must succeed.

## 12. Install NixOS

Install using the pinned flake:

```bash
nixos-install \
  --flake "/mnt/etc/nixos#${HOST}" \
  --no-root-passwd
```

Do not use `--upgrade` and do not update `flake.lock` during installation.

The user password comes from the locally created hash file.

If installation fails because of a configuration issue, fix it in `/mnt/etc/nixos`, stage the changed declarative files with `git add`, rerun:

```bash
nix flake check
```

and then rerun `nixos-install`.

## 13. Reboot

When `nixos-install` completes successfully:

```bash
sync
cd /
umount -R /mnt
reboot
```

Remove the installer media when the firmware begins rebooting.

## 14. Verify the installed system

After logging in as `gustavo`:

```bash
nixos-version
```

Check for failed system units:

```bash
systemctl --failed
```

Check for failed user units:

```bash
systemctl --user --failed
```

Check listening network sockets:

```bash
sudo ss -lntup
```

Check that the flake can still validate all machines:

```bash
cd /etc/nixos
nix flake check
```

## 15. Commit the new host

The new machine-specific hardware file and host module should be committed so the machine can be reproduced later.

The local password hash must **not** be committed.

From `/etc/nixos`:

```bash
sudo git status
```

Confirm that `secrets/` is absent from the staged files.

Then:

```bash
sudo git add flake.nix "hosts/$HOST"
sudo git commit -m "Add $HOST"
```

Push using the normal repository workflow.

## Normal operation after installation

Rebuild without changing dependency versions:

```bash
rebuild
```

The configured alias should first run the flake checks and only switch the current machine if every configured host builds.

To update Nixpkgs and Home Manager deliberately:

```bash
cd /etc/nixos
sudo nix flake update
nix flake check
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

After a successful update, commit the new lock file:

```bash
sudo git add flake.lock
sudo git commit -m "Update flake inputs"
```

For another machine, use that machine's flake name instead of `#nixos`.

## Recovery principles

The repository plus the locally recreated password hash is sufficient to reconstruct the software environment.

The only files that should differ fundamentally between machines are:

```text
hosts/<hostname>/default.nix
hosts/<hostname>/hardware-configuration.nix
```

Everything else should remain shared unless there is a real machine-specific reason to split it.

Do not change these simply because NixOS was upgraded:

```nix
system.stateVersion = "25.11";
home.stateVersion = "25.11";
```

They are compatibility versions, not the currently installed NixOS release.
