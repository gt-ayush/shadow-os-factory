#!/bin/bash

set -e

echo "🚀 Shadow OS Build Started"

# ==============================
# 🛡️ SAFETY CHECKS
# ==============================
if ! command -v lb >/dev/null; then
    echo "❌ live-build not installed"
    exit 1
fi

# ==============================
# 🧠 LOW RAM SETTINGS
# ==============================
export TMPDIR=/tmp
mkdir -p "$TMPDIR"

# Reduce CPU → less RAM pressure
export MAKEFLAGS="-j1"

# Non-interactive debconf so apt/dpkg never block on a prompt.
export DEBIAN_FRONTEND=noninteractive

# Reduce I/O priority (keeps system responsive)
ionice -c2 -n7 -p $$ >/dev/null 2>&1 || true

# ==============================
# 🧹 CLEAN CONFIGURATION
# ==============================
if [ "$1" = "--purge" ]; then
    echo "🧹 [PURGE MODE] Deep cleaning all previous build files and cached packages..."
    lb clean --purge
else
    echo "🧹 [STANDARD MODE] Performing quick clean (caching preserved)..."
    lb clean
fi

# ==============================
# ⚙️ CONFIG
# ==============================
echo "⚙️ Configuring live-build..."

lb config \
    --mode debian \
    --system live \
    --distribution trixie \
    --archive-areas "main contrib non-free non-free-firmware" \
    --linux-flavours amd64 \
    --debian-installer live \
    --binary-images iso-hybrid \
    --memtest memtest86+ \
    --apt-recommends false \
    --backports true

# ==============================
# 🏗️ BUILD
# ==============================
echo "🏗️ Building ISO..."

# Avoid RAM-heavy tee
lb build > shadow-build.log 2>&1

# ==============================
# ✅ RESULT
# ==============================
if [ -f "live-image-amd64.hybrid.iso" ]; then
    mv live-image-amd64.hybrid.iso "shadow-os-alpha-v0.1.6.iso"
    echo "✅ SUCCESS: ISO created!"
else
    echo "❌ ERROR: Build failed. Check shadow-build.log"
fi
