# NixOS installation

Boot the NixOS installer ISO and connect to Wi-Fi:

```bash
nmtui
```

Clone the configuration:

```bash
git clone <REPO_URL> /tmp/nixos
cd /tmp/nixos
```

Find the target disk:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL
```

Install, choosing a hostname and disk:

```bash
./install.sh laptop /dev/nvme0n1
```

> **Warning:** the selected disk is erased completely.

When installation finishes:

```bash
sudo reboot
```

After booting the new system, save its generated hardware configuration:

```bash
cd /etc/nixos
git add hosts/laptop/hardware-configuration.nix
git commit -m "Add laptop"
git push
```
