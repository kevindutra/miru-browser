#!/bin/zsh
# Rebuild all Miru marketing images from raw/ captures.
#
#   ./build.sh          App Store screenshots + header/search assets into app-store/,
#                       website hero into build/site-hero.png
#   ./build.sh --jpeg   also write sRGB JPEG copies to build/jpeg/ (for stuck uploads)
#
# Needs Google Chrome and Python 3 with Pillow.
set -e
cd "${0:A:h}"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

python3 gen.py >/dev/null
python3 creative.py >/dev/null
python3 site_hero.py >/dev/null

mkdir -p build/out
for f in build/*.html; do
  n=${f:t:r}
  bg=()
  case $n in
    iphone-*) sz=1320,2868 ;;
    ipad-*) sz=2064,2752 ;;
    creative-header) sz=3840,1646 ;;
    creative-search) sz=3840,2560 ;;
    site-hero) sz=1240,1520; bg=(--default-background-color=00000000) ;;
  esac
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=8000 $bg \
    --window-size=$sz --screenshot="$PWD/build/out/$n.png" "file://$PWD/$f" >/dev/null 2>&1
done

python3 - "$@" <<'EOF'
import sys, glob, os
from PIL import Image, ImageCms

def save_rgb(src, dst, size=None):
    im = Image.open(src).convert("RGB")  # App Store rejects alpha channels
    if size:
        im = im.resize(size, Image.LANCZOS)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    im.save(dst)

for f in sorted(glob.glob("build/out/iphone-*.png")):
    name = os.path.basename(f).removeprefix("iphone-")
    save_rgb(f, f"app-store/iphone-6.9/{name}")
    save_rgb(f, f"app-store/iphone-6.3/{name}", (1206, 2622))
for f in sorted(glob.glob("build/out/ipad-*.png")):
    save_rgb(f, f"app-store/ipad-13/{os.path.basename(f).removeprefix('ipad-')}")
save_rgb("build/out/creative-header.png", "app-store/creative/header-3840x1646.png")
save_rgb("build/out/creative-search.png", "app-store/creative/search-results-3840x2560.png")

hero = Image.open("build/out/site-hero.png").convert("RGBA")
hero.crop(hero.getbbox()).save("build/site-hero.png")

if "--jpeg" in sys.argv:
    icc = ImageCms.ImageCmsProfile(ImageCms.createProfile("sRGB")).tobytes()
    for f in glob.glob("app-store/*/*.png"):
        out = "build/jpeg/" + f.removeprefix("app-store/")[:-4] + ".jpg"
        os.makedirs(os.path.dirname(out), exist_ok=True)
        Image.open(f).save(out, "JPEG", quality=92, icc_profile=icc, subsampling=0)
EOF
echo "Done: app-store/ updated, website hero at build/site-hero.png"
