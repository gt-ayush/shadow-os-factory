
#!/bin/bash

sudo lb clean --purge

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

# 2. Build the ISO and log the output
sudo lb build 2>&1 | tee shadow-build.log

# 3. Check if successful
if [ -f "live-image-amd64.hybrid.iso" ]; then
    mv live-image-amd64.hybrid.iso shadow-os-v1-alpha\ 0.3.iso
    echo "Success: shadow-os-v1-alpha 0.3.iso created."
else
    echo "Error: Build failed. Check shadow-build.log"
fi
