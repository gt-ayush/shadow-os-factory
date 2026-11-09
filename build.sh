#!/usr/bin/env bash
set -euo pipefail

# Shadow OS - live-build wrapper (Debian Live Manual workflow)
# Usage:
#   ./build.sh            # clean (preserve cache) + config + build
#   ./build.sh --purge    # full clean (remove cache) + config + build
#
# Release metadata (version/channel/build) comes from release.env.
# Edit release.env directly or run ./scripts/update-release.sh.
# Override ISO basename/version via IMAGE_BASENAME / IMAGE_VERSION env vars.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- release metadata (single source of truth) ---
RELEASE_ENV="${SCRIPT_DIR}/release.env"
if [ -f "$RELEASE_ENV" ]; then
  # shellcheck disable=SC1090
  . "$RELEASE_ENV"
fi

SHADOW_NAME="${SHADOW_NAME:-Shadow OS}"
SHADOW_ID="${SHADOW_ID:-shadow}"
SHADOW_VERSION="${SHADOW_VERSION:-0.0.0}"
SHADOW_CHANNEL="${SHADOW_CHANNEL:-alpha}"
SHADOW_BUILD_ID="${SHADOW_BUILD_ID:-auto}"
SHADOW_ARCH="${SHADOW_ARCH:-amd64}"

case "$SHADOW_BUILD_ID" in
  ''|auto|AUTO|timestamp)
    SHADOW_BUILD_ID="$(date '+%Y-%m-%dT%H:%M:%S%z')"
    ;;
esac

_channel_lower="$(printf '%s' "$SHADOW_CHANNEL" | tr '[:upper:]' '[:lower:]')"
if [ "$_channel_lower" = "stable" ]; then
  _release_tag="v${SHADOW_VERSION}"
  _release_label="${SHADOW_NAME} v${SHADOW_VERSION}"
else
  _release_tag="v${SHADOW_VERSION}-${_channel_lower}"
  _release_label="${SHADOW_NAME} v${SHADOW_VERSION}-${_channel_lower}"
fi

IMAGE_BASENAME="${IMAGE_BASENAME:-${SHADOW_ID}-os}"
IMAGE_VERSION="${IMAGE_VERSION:-${_release_tag}}"
IMAGE_ARCH="${IMAGE_ARCH:-${SHADOW_ARCH}}"
LOG_FILE="${LOG_FILE:-shadow-build.log}"
ISO_VOLUME="$(printf 'SHADOWOS_%s_%s' "$SHADOW_VERSION" "$_channel_lower" | tr '.-' '_' | tr '[:lower:]' '[:upper:]' | cut -c1-32)"

echo "==> ${_release_label} build started (image: ${IMAGE_BASENAME}-${IMAGE_VERSION}-${IMAGE_ARCH}, build: ${SHADOW_BUILD_ID})"

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
  --image-name "${IMAGE_BASENAME}" \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --architectures "${IMAGE_ARCH}" \
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
  --iso-application "${_release_label}" \
  --iso-preparer "Shadow OS live-build; ${SHADOW_HOME_URL:-https://shadow-os.x}" \
  --iso-publisher "${SHADOW_MAINTAINER:-Shadow OS}" \
  --iso-volume "${ISO_VOLUME}" \
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
isos=( "${IMAGE_BASENAME}-"*.hybrid.iso "${IMAGE_BASENAME}-"*.iso live-image-*.hybrid.iso live-image-*.iso *.hybrid.iso *.iso )
shopt -u nullglob
if [ "${#isos[@]}" -gt 0 ]; then
  src="${isos[0]}"
  dest="${IMAGE_BASENAME}-${IMAGE_VERSION}-${IMAGE_ARCH}.hybrid.iso"
  if [ "$src" != "$dest" ]; then
    mv -f -- "$src" "$dest"
  fi
  echo "==> SUCCESS: ${dest}"
  echo "==> Log: ${LOG_FILE}"
else
  echo "ERROR: build completed but no ISO was found. Check ${LOG_FILE}" >&2
  exit 1
fi
