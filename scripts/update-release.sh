#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/release.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

valid_channel() {
  case "$1" in
    alpha|beta|rc|stable) return 0 ;;
    *) return 1 ;;
  esac
}

title_case_channel() {
  case "$1" in
    alpha) printf 'Alpha' ;;
    beta) printf 'Beta' ;;
    rc) printf 'RC' ;;
    stable) printf 'Stable' ;;
    *) printf '%s' "$1" ;;
  esac
}

prompt_default() {
  local var="$1" prompt="$2" default="$3" value
  read -r -p "$prompt [$default]: " value || true
  printf -v "$var" '%s' "${value:-$default}"
}

resolve_build_id() {
  local value="$1"
  case "$value" in
    ''|auto|AUTO|timestamp)
      date '+%Y-%m-%dT%H:%M:%S%z'
      ;;
    *)
      printf '%s' "$value"
      ;;
  esac
}

echo "==> Shadow OS release updater"
echo "Current: version=${SHADOW_VERSION} channel=${SHADOW_CHANNEL} build=${SHADOW_BUILD_ID}"
echo "Tip: set Build ID to 'auto' for current timestamp with timezone, or enter a custom value."
echo

while true; do
  prompt_default NEW_CHANNEL "Release channel (alpha/beta/rc/stable)" "${SHADOW_CHANNEL}"
  NEW_CHANNEL="$(printf '%s' "$NEW_CHANNEL" | tr '[:upper:]' '[:lower:]')"
  if valid_channel "$NEW_CHANNEL"; then break; fi
  echo "Invalid channel: $NEW_CHANNEL"
done

prompt_default NEW_VERSION "Version (e.g. 0.1.6)" "${SHADOW_VERSION}"
prompt_default NEW_BUILD "Build ID (auto = timestamp+timezone, or custom)" "${SHADOW_BUILD_ID}"
prompt_default NEW_CODENAME "Version codename" "${SHADOW_VERSION_CODENAME}"

RESOLVED_BUILD="$(resolve_build_id "$NEW_BUILD")"

CHANNEL_TITLE="$(title_case_channel "$NEW_CHANNEL")"
if [ "$NEW_CHANNEL" = "stable" ]; then
  RELEASE_TAG="V${NEW_VERSION}"
  PRETTY_TAG="V${NEW_VERSION}"
  VERSION_DISPLAY="V${NEW_VERSION} (${SHADOW_BASE})"
else
  RELEASE_TAG="V${NEW_VERSION}-${CHANNEL_TITLE}"
  PRETTY_TAG="V${NEW_VERSION}-${CHANNEL_TITLE}"
  VERSION_DISPLAY="V${NEW_VERSION}-${CHANNEL_TITLE} (${SHADOW_BASE})"
fi

# Update release.env (preserve 'auto' if chosen; resolved timestamp is written to branding files)
tmp="$(mktemp)"
awk -v v="$NEW_VERSION" -v c="$NEW_CHANNEL" -v b="$NEW_BUILD" -v n="$NEW_CODENAME" '
  /^SHADOW_VERSION=/ { print "SHADOW_VERSION=\"" v "\""; next }
  /^SHADOW_CHANNEL=/ { print "SHADOW_CHANNEL=\"" c "\"          # alpha, beta, rc, stable"; next }
  /^SHADOW_BUILD_ID=/ { print "SHADOW_BUILD_ID=\"" b "\""; next }
  /^SHADOW_VERSION_CODENAME=/ { print "SHADOW_VERSION_CODENAME=\"" n "\""; next }
  { print }
' "$ENV_FILE" > "$tmp" && mv "$tmp" "$ENV_FILE"

# os-release
cat > "${REPO_ROOT}/config/includes.chroot_after_packages/etc/os-release" <<EOF
NAME="${SHADOW_NAME}"
VERSION="${VERSION_DISPLAY}"
ID=${SHADOW_ID}
ID_LIKE=debian
PRETTY_NAME="${SHADOW_NAME} ${PRETTY_TAG}"
VERSION_ID="${NEW_VERSION}"
VERSION_CODENAME=${NEW_CODENAME}
BUILD_ID="${RESOLVED_BUILD}"

HOME_URL="${SHADOW_HOME_URL}"
SUPPORT_URL="${SHADOW_SUPPORT_URL}"
BUG_REPORT_URL="${SHADOW_BUG_URL}"

ANSI_COLOR="1;35"
LOGO=shadow
EOF

# lsb-release
cat > "${REPO_ROOT}/config/includes.chroot_after_packages/etc/lsb-release" <<EOF
DISTRIB_ID=${SHADOW_ID}
DISTRIB_RELEASE=${RELEASE_TAG}
DISTRIB_CODENAME=${NEW_CODENAME}
DISTRIB_DESCRIPTION="${SHADOW_NAME} ${VERSION_DISPLAY}"
EOF

# shadow-release
cat > "${REPO_ROOT}/config/includes.chroot_after_packages/etc/shadow-release" <<EOF
${SHADOW_NAME} ${RELEASE_TAG}

Edition: ${SHADOW_EDITION}
Base: ${SHADOW_BASE}
Kernel: Linux 6.x
Desktop: KDE Plasma 6

Build: ${RESOLVED_BUILD}
Architecture: ${SHADOW_ARCH}

Maintainer: ${SHADOW_MAINTAINER}
EOF

echo
echo "Updated:"
echo " - release.env"
echo " - config/includes.chroot_after_packages/etc/os-release"
echo " - config/includes.chroot_after_packages/etc/lsb-release"
echo " - config/includes.chroot_after_packages/etc/shadow-release"
echo
echo "Release: ${SHADOW_NAME} ${RELEASE_TAG} (build ${RESOLVED_BUILD}${NEW_BUILD:+; release.env: ${NEW_BUILD}})"
