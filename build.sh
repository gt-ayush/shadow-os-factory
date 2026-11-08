#!/usr/bin/env bash
set -euo pipefail

# Shadow OS - live-build wrapper (Debian Live Manual workflow)
# Usage:
#   ./build.sh            # clean (preserve cache) + config + build
#   ./build.sh --purge    # full clean (remove cache) + config + build

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_BASENAME="${IMAGE_BASENAME:-shadow-os}"
IMAGE_VERSION="${IMAGE_VERSION:-$(date +%Y%m%d)}"
LOG_FILE="${LOG_FILE:-shadow-build.log}"

echo "==> Shadow OS build started (${IMAGE_BASENAME}-${IMAGE_VERSION})"

# --- checks ---
if ! command -v lb >/dev/null 2>&1; then
  echo "ERROR: live-build (lb) not found in PATH." >&2
  exit 1
fi

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "WARN: not running as root; live-build usually needs root or a properly privileged container." >&2
fi

# --- environment (low-resource friendly) ---
export TMPDIR="${TMPDIR:-/tmp}"
mkdir -p "$TMPDIR"
export MAKEFLAGS="${MAKEFLAGS:--j1}"
export DEBIAN_FRONTEND=noninteractive
ionice -c2 -n7 -p "$$" >/dev/null 2>&1 || true

# --- clean ---
if [ "${1:-}" = "--purge" ]; then
  echo "==> Purge clean (removes cache/build state)"
  lb clean --purge || true
else
  echo "==> Clean (preserving cache where possible)"
  lb clean || true
fi

# --- config (documentation-aligned) ---
# - boot=live components: required for live-boot/live-config runtime behavior
# - --firmware-chroot false: avoids b43-installer/legacy postinst network downloads
# - --apt-recommends true: keep recommends as requested (larger image)
echo "==> Configuring live-build"
lb config \
  --mode debian \
  --system live \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --architectures amd64 \
  --linux-flavours amd64 \
  --debian-installer live \
  --binary-images iso-hybrid \
  --bootloader "grub-efi,grub-pc" \
  --bootappend-live "boot=live components quiet splash" \
  --bootappend-live-failsafe "boot=live components memtest noapic noapm nodma nomce nosmp nosplash vga=788" \
  --memtest memtest86+ \
  --apt-recommends true \
  --apt-indices true \
  --security true \
  --updates true \
  --backports true \
  --firmware-chroot false \
  --firmware-binary true \
  --checksums "sha256" \
  --cache true

# --- build ---
echo "==> Building image (log: ${LOG_FILE})"
if lb build >"${LOG_FILE}" 2>&1; then
  :
else
  status=$?
  echo "ERROR: lb build failed (exit ${status}). See ${LOG_FILE}" >&2
  tail -n 60 "${LOG_FILE}" >&2 || true
  exit "${status}"
fi

# --- result ---
shopt -s nullglob
isos=( live-image-*.hybrid.iso live-image-*.iso *.hybrid.iso )
shopt -u nullglob
if [ "${#isos[@]}" -gt 0 ]; then
  src="${isos[0]}"
  dest="${IMAGE_BASENAME}-${IMAGE_VERSION}-amd64.hybrid.iso"
  if [ "$src" != "$dest" ]; then
    mv -f -- "$src" "$dest"
  fi
  echo "==> SUCCESS: ${dest}"
  echo "==> Log: ${LOG_FILE}"
else
  echo "ERROR: build completed but no ISO was found. Check ${LOG_FILE}" >&2
  exit 1
fi
