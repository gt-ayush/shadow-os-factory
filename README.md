# Shadow OS Factory

Build tooling for **Shadow OS**, a custom Debian **trixie** (amd64) live image built with [`live-build`](https://live-team.pages.debian.net/live-manual/html/live-manual.en.html). The desktop stack targets **KDE Plasma (minimal) + SDDM** with PipeWire and NetworkManager.

> **Source of truth:** follow the [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual.en.html). See [`AGENTS.md`](./AGENTS.md) for agent/project guidance, pitfalls, and the roadmap.

## Current state

- Branch: `issue` (documentation-aligned rebuild in progress; keep commits/history).
- Base package lists are in `config/package-lists/` (live, core, firmware, desktop, apps, dev).
- **Zen Browser** is installed via `config/hooks/normal/0500-install-zen-browser.hook.chroot` (downloads the official Linux tarball at build time; no Debian `.deb` repo). Pin with `ZEN_BROWSER_URL=...` if needed.
- `cache/` and `chroot/` may contain **root-owned** leftovers from previous builds — remove with `sudo rm -rf cache chroot` before a clean rebuild.

## Prerequisites

On a Debian/Ubuntu host (or a privileged container):

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools
```

Builds require network access to Debian mirrors and (with current config) to download the Zen Browser tarball.

## Container build

`live-build` performs chroot/bootstrap operations that typically require root privileges and can be sensitive to host configuration. Building inside a clean Debian **trixie** container is a good way to keep the host clean and make builds reproducible.

`build.sh` is container-friendly (it warns but does not exit if not running as root).

### Docker / Podman example

Run from the repository root (bind-mounts the workspace so the ISO/logs are written back to the host):

```bash
# Docker
docker run --rm -it --privileged \
  -v "$PWD":/work -w /work \
  debian:trixie bash

# Podman (similar)
# podman run --rm -it --privileged -v "$PWD":/work -w /work debian:trixie bash
```

Inside the container:

```bash
apt-get update
apt-get install -y live-build debootstrap squashfs-tools xorriso \
  grub-pc-bin grub-efi-amd64-bin mtools dosfstools ca-certificates curl git

./build.sh          # or ./build.sh --purge
```

Notes:
- `--privileged` (or equivalent capabilities/devices/mount permissions) is often needed for `debootstrap`/chroot/mount operations used by `live-build`. Use the least-privileged setup that works in your environment.
- If you run `./build.sh` without `--purge`, cached/root-owned files under `cache/` or `chroot/` may remain; clean them with `rm -rf cache chroot` (as root in the container) when needed.
- The ISO, `shadow-build.log`, and generated `config/` files are created in `/work` (your mounted repo).

## Build

```bash
# standard clean (preserves cache where possible) + config + build
./build.sh

# full clean rebuild (removes cache/build state; slow)
./build.sh --purge
```

Useful overrides:

```bash
IMAGE_BASENAME=shadow-os IMAGE_VERSION=alpha ./build.sh
ZEN_BROWSER_URL=https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz ./build.sh
```

Output: `shadow-os-<version>-amd64.hybrid.iso` (or `live-image-*.hybrid.iso` renamed) and `shadow-build.log`. On failure, the script prints the last lines of the log.

### Key `lb config` choices (`build.sh`)

- `--bootappend-live "boot=live components quiet splash"` — **`components` is required** for `live-config` (live user, runtime hooks).
- `--bootloader "grub-efi,grub-pc"` / `--binary-images iso-hybrid`.
- `--apt-recommends true` (project preference).
- `--firmware-chroot false` to avoid `firmware-b43-installer`/`firmware-b43legacy-installer` postinst network-download failures; add firmware explicitly in `config/package-lists/firmware.list.chroot`. `--firmware-binary true` remains enabled.

## Repository layout

```text
build.sh                 # build entry point (durable lb config flags)
AGENTS.md                # doc links, pitfalls, roadmap
config/
  package-lists/         # *.list.chroot package selection
  hooks/normal/          # chroot hooks run during build (e.g. Zen install)
  includes.chroot/       # files overlaid into / (before/early; packages may overwrite)
  includes.chroot_after_packages/  # overlaid after package install (can override package files)
  archives/              # apt prefs/sources (if needed)
  apt/                   # apt config snippets (if needed)
```

As you add features (doc-aligned), expect:

- `config/includes.chroot/etc/live/config.conf.d/*.conf` — **variables only** (e.g. live user/groups). Do **not** put commands (`su`, `lookandfeeltool`) here.
- `config/includes.chroot/lib/live/config/` — sequenced `live-config` hooks/components for boot-time actions (password handling, SDDM/autologin overrides, post-user setup).
- `config/includes.chroot/etc/sddm.conf.d/*.conf` — SDDM drop-in config (theme/autologin compatibility).

## Debugging

- **Build failures:** inspect the tail of `shadow-build.log`. Distinguish **fetch/mirror errors**, **dpkg/trigger/configure errors**, and **live-config runtime** issues.
- **Live boot/login issues:** boot with `live-config.debug` and check:

```bash
getent passwd <live-user>
cat /proc/cmdline                  # should include boot=live components
ls /var/lib/live/config
ls /etc/sddm.conf.d/ 2>/dev/null
journalctl -b | grep -E 'live-config|user-setup|sddm'
```

## Known pitfalls

- `LIVE_PASSWORD` in `config.conf.d` is **not** applied by stock `0030-user-setup` (live-config 11.x) — implement password via a proper `lib/live/config/` hook/component.
- `LIVE_USER_DEFAULT_GROUPS` must contain only groups that exist in the image (e.g. avoid `powerdev`/`scanner` unless present).
- SDDM `Current=<theme>` only works if `/usr/share/sddm/themes/<theme>` exists.
- Large `--apt-recommends true` desktop builds can expose trigger issues (e.g. `dictionaries-common`/`aspell-autobuildhash`). Keep fixes minimal, targeted, and documented.

## License / notes

Shadow OS configuration in this repository; upstream Debian/live-build/live-config components are under their respective licenses. Zen Browser is third-party software installed from upstream releases by the build hook.