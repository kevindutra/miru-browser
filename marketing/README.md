# Marketing images

App Store screenshots, App Store header/search assets, and the mirubrowser.com
hero, all generated from real simulator captures.

| Folder | What | Size |
|---|---|---|
| `app-store/iphone-6.9/` | iPhone 6.9" screenshots (required; also covers 6.5") | 1320 × 2868 |
| `app-store/iphone-6.3/` | iPhone 6.3" (only if App Store Connect asks) | 1206 × 2622 |
| `app-store/ipad-13/` | iPad 13" screenshots | 2064 × 2752 |
| `app-store/creative/` | Product page header and search results asset | 3840 × 1646, 3840 × 2560 |
| `raw/` | Simulator captures the images are built from | native |

## Rebuilding

Edit the copy in `gen.py` (`SLIDES`) or `creative.py`, then:

```sh
./build.sh          # rewrites app-store/, plus build/site-hero.png for the website
./build.sh --jpeg   # also build/jpeg/, sRGB JPEGs if App Store uploads get stuck
```

Needs Google Chrome and Python 3 with Pillow. `build/` is scratch output and
is gitignored. The website hero goes in the site repo as `static/miru_browser.png`.

## Recapturing `raw/`

Captures come from the iPhone 17 Pro Max and iPad Pro 13" (M5) simulators,
with the status bar overridden:

```sh
xcrun simctl status_bar <device> override --time 9:41 --batteryState charged \
  --batteryLevel 100 --wifiBars 3 --cellularBars 4 --dataNetwork wifi
```

Settings and pages can't be reached by tapping from the command line, so the
captures used temporary, uncommitted hooks in a local build:

- `ContentView.swift`: start `showSettings` as
  `ProcessInfo.processInfo.arguments.contains("-screenshotSettings")`
- `Miru_BrowserApp.swift`: a `.task` that loads
  `UserDefaults.standard.string(forKey: "screenshotURL")` after a second
- `Info.plist`: `UIRequiresFullScreen = true` so the iPad launches full screen

Then, for example:

```sh
xcrun simctl launch <device> miru.Miru-Browser -screenshotURL "https://en.wikipedia.org/wiki/Night_sky?banner=none"
xcrun simctl io <device> screenshot raw/iphone-wiki2.png
```

`?banner=none` hides Wikipedia's fundraising and app banners. Revert the hooks
before committing.
