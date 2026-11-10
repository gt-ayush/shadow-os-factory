# Container Build Environment

This note documents how to build **Shadow OS** inside a container. Building in a clean, isolated container keeps the host system untouched, avoids dependency conflicts, and provides a reproducible environment for `live-build`.

> Based on the container workflow documented in `main:readme.md`, adapted to the current `issue` branch build (`build.sh`, Debian **trixie**, `--bootloader grub-efi,grub-pc`, Zen Browser hook, `release.env`).

## Why use a container

`live-build`/`debootstrap` perform chroot creation, package installation, filesystem mounts, loop-device operations, and boot image assembly. These steps typically require elevated privileges and can leave root-owned artifacts (`chroot/`, `cache/`, generated files). A dedicated container:

- isolates build dependencies from the host (works well on non-Debian hosts such as Arch/Fedora)
- reduces host loop-device/mount pollution
- makes the toolchain repeatable
- keeps all outputs in the mounted repository directory

## Recommended base image

Use a **Debian trixie** image to match the target distribution configured in `build.sh` (`--distribution trixie`):

- Docker: `debian:trixie`
- Podman: `docker.io/library/debian:trixie` (or `debian:trixie-slim` if you prefer a smaller base)

Using `stable`/`stable-slim` may work, but can diverge from trixie depending on when Debian stable changes; prefer an explicit trixie tag for consistency.

## Host prerequisites

- **Podman** or **Docker** installed on the host
- Sufficient disk space (several GB for bootstrap/cache/chroot/squashfs/ISO; more with `--apt-recommends true`)
- Network access to Debian mirrors and to GitHub releases (current build downloads Zen Browser via `config/hooks/normal/0500-install-zen-browser.hook.chroot`, unless `ZEN_BROWSER_REQUIRED=false` or `ZEN_BROWSER_URL` points to a local/mirrored asset)
- A host kernel/filesystem setup that allows privileged container mounts/loop devices as required by `live-build`

Run commands from the **root of the `shadow-os-factory` repository**.

## Podman (recommended workflow from `main`)

### 1. Launch the builder container

```bash
podman run -it --name shadow-os-factory \
  --privileged \
  --cap-add=ALL \
  -v /dev:/dev \
  -v .:/build:z \
  docker.io/library/debian:trixie /bin/bash
```

#### Option breakdown

| Option | Purpose |
|---|---|
| `--name shadow-os-factory` | Names the container so you can restart/re-enter it later. |
| `--privileged` | Grants broad privileges needed by `live-build` for chroot, mounts, loop devices, and image assembly. |
| `--cap-add=ALL` | Adds all Linux capabilities (often redundant with `--privileged`, but explicit and harmless). |
| `-v /dev:/dev` | Exposes host device nodes so `live-build`/mount/loop operations can access loop devices as needed. |
| `-v .:/build:z` | Bind-mounts the repository into `/build`. Outputs (ISO, `shadow-build.log`, generated `config/` state) are written back to the host. `:z` relabels for SELinux shared access (useful on Fedora/RHEL hosts); omit or adjust if not using SELinux. |
| `docker.io/library/debian:trixie` | Build environment base image. |
| `/bin/bash` | Interactive shell. |

> **Security note:** `--privileged` gives the container extensive control over the host. Use it only for trusted build workloads. If your environment supports a narrower set of capabilities/devices/mount options for `live-build`, prefer the least-privileged configuration that works.

### 2. Install dependencies and build (inside the container)

```bash
# Move to the mounted project
cd /build

# Install live-build and required tools
apt-get update
apt-get install -y --no-install-recommends \
  live-build debootstrap squashfs-tools xorriso \
  grub-pc-bin grub-efi-amd64-bin mtools dosfstools \
  cpio file rsync wget curl ca-certificates git

# Build
chmod +x build.sh scripts/update-release.sh
./build.sh
```

For a full clean rebuild (removes cache/build state; slower):

```bash
./build.sh --purge
# if root-owned leftovers remain:
rm -rf cache chroot
./build.sh --purge
```

### 3. Re-enter an existing container

If you exit the shell, reuse the same container (dependencies remain installed):

```bash
podman start shadow-os-factory
podman exec -it shadow-os-factory /bin/bash
# then: cd /build && ./build.sh
```

To remove and recreate it:

```bash
podman rm -f shadow-os-factory
```

## Docker equivalent

```bash
docker run -it --name shadow-os-factory \
  --privileged \
  --cap-add=ALL \
  -v /dev:/dev \
  -v "$PWD":/build \
  debian:trixie /bin/bash
```

Re-enter:

```bash
docker start shadow-os-factory
docker exec -it shadow-os-factory /bin/bash
```

(Docker typically does not need `:z`; keep `$PWD` quoted.)

## Project-specific build notes

- **Entry point:** `./build.sh` is the durable wrapper around `lb config` + `lb build`. It sources `release.env` for branding/versioning and ISO naming (e.g. `shadow-os-v0.1.6-alpha-amd64.hybrid.iso`).
- **Release metadata:** edit `release.env` or run `./scripts/update-release.sh` (channel: `alpha|beta|rc|stable`, version, `BUILD_ID` defaults to `auto` = timestamp with timezone, codename) before building.
- **Key `lb config` choices:** `--distribution trixie`, `--architectures amd64`, `--binary-images iso-hybrid`, `--bootloader "grub-efi,grub-pc"`, `--bootappend-live "boot=live components quiet splash"`, `--apt-recommends true`, `--firmware-chroot false`, `--firmware-binary true`.
- **Zen Browser:** installed at build time by `config/hooks/normal/0500-install-zen-browser.hook.chroot` (requires network). Override with `ZEN_BROWSER_URL=...`; skip (not recommended) with `ZEN_BROWSER_REQUIRED=false`.
- **Logs/output:** build log is `shadow-build.log`; on failure `build.sh` prints the tail. The ISO is written to the repo root (`/build` in the container).
- **Root-owned artifacts:** `cache/` and `chroot/` may be owned by root after a build. Clean from inside the container (`rm -rf cache chroot`) or with `sudo` on the host if needed.
- **Non-root warning:** `build.sh` warns if not running as root but continues; in a properly privileged container this is usually fine.

## Troubleshooting

| Symptom | Likely cause / action |
|---|---|
| Mount/loop/chroot errors in `lb build` | Container not privileged or `/dev` not exposed; ensure `--privileged` and `-v /dev:/dev` (or equivalent). |
| `lb: command not found` | Install `live-build` inside the container. |
| Mirror/network errors, `curl: (35)` / Zen download fails | Transient network issue or blocked GitHub; retry, or set `ZEN_BROWSER_URL` to a pinned/mirrored asset. |
| `Permission denied` cleaning `cache/`/`chroot/` on host | Artifacts created as root in container; remove with `sudo rm -rf cache chroot` on host or `rm -rf cache chroot` in container. |
| ISO not found but build reported success | Check repo root for `${IMAGE_BASENAME}-*.iso`; inspect `shadow-build.log`. |
| SELinux denies bind-mount writes (Podman/Fedora hosts) | Use `:z` (or `:Z` if appropriate) on the volume mount. |

## Minimal one-shot example (ephemeral container)

```bash
podman run --rm -it --privileged --cap-add=ALL \
  -v /dev:/dev -v "$PWD":/build:z -w /build \
  docker.io/library/debian:trixie bash -lc '
    apt-get update &&
    apt-get install -y --no-install-recommends \
      live-build debootstrap squashfs-tools xorriso \
      grub-pc-bin grub-efi-amd64-bin mtools dosfstools \
      cpio file rsync wget curl ca-certificates git &&
    ./build.sh
  '
```

Remove `--rm` and add `--name shadow-os-factory` if you want to keep the container for iterative rebuilds.
