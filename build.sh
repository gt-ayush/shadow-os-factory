#!/bin/bash

set -e

echo "🚀 Shadow OS Build Started"

# ==============================
# 🛡️ SAFETY CHECKS
# ==============================
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Do NOT run this script as root"
    exit 1
fi

if ! command -v lb >/dev/null; then
    echo "❌ live-build not installed"
    exit 1
fi

# ==============================
# 🧠 LOW RAM SETTINGS
# ==============================
export TMPDIR=$HOME/tmp
mkdir -p "$TMPDIR"

# Reduce CPU → less RAM pressure
export MAKEFLAGS="-j1"

# Reduce I/O priority (keeps system responsive)
ionice -c2 -n7 -p $$ >/dev/null 2>&1 || true

# ==============================
# 🔓 PREVENT SLEEP (CRITICAL)
# ==============================
echo "🔓 Disabling sleep..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ==============================
# 🧹 CLEAN
# ==============================
echo "🧹 Cleaning previous build..."
sudo lb clean --purge

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
    --apt-recommends true \
    --backports true

# ==============================
# 🏗️ BUILD
# ==============================
echo "🏗️ Building ISO..."

# Avoid RAM-heavy tee
sudo lb build > shadow-build.log 2>&1

# ==============================
# ✅ RESULT
# ==============================
if [ -f "live-image-amd64.hybrid.iso" ]; then
    mv live-image-amd64.hybrid.iso "shadow-os-alpha-v0.1.5.iso"
    echo "✅ SUCCESS: ISO created!"

    echo "⚠️ System will shutdown in 60 seconds (Ctrl+C to cancel)"
    sleep 60

else
    echo "❌ ERROR: Build failed. Check shadow-build.log"
fi

# ==============================
# 🔒 RESTORE SYSTEM
# ==============================
echo "🔒 Restoring system state..."
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ==============================
# ⛔ SHUTDOWN
# ==============================
echo "🛑 Shutting down..."
sudo shutdown -h now
