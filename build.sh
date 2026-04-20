#!/bin/bash

set -e

# Use temp dir to reduce RAM pressure
export TMPDIR=$HOME/tmp
mkdir -p $TMPDIR

# Limit CPU usage (important for 16GB RAM)
export MAKEFLAGS="-j2"

echo "🧹 Cleaning previous build..."
sudo lb clean --purge

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

echo "🏗️ Building ISO..."

sudo lb build 2>&1 | tee shadow-build.log

if [ -f "live-image-amd64.hybrid.iso" ]; then
    mv live-image-amd64.hybrid.iso "shadow-os-alpha-v0.1.1.iso"
    echo "✅ SUCCESS: ISO created!"
else
    echo "❌ ERROR: Build failed. Check shadow-build.log"
fi
