# Miru Browser

A minimal, calm iOS browser. Miru opens links, blocks ads, and gets out of the
way — no tabs, no accounts, no data collected.

[Download on the App Store](https://apps.apple.com/app/id6757682680) ·
[mirubrowser.com](https://mirubrowser.com)

## What it does

- **Opens links.** Set Miru as your default browser and any http/https link
  from another app opens in it.
- **One bookmark, chosen once.** The globe on the home screen opens Wikipedia
  until you pick your own site in Settings. Once it's set, it's set for good.
- **Blocks ads.** Built-in content blocking from EasyList, refreshed in the
  background.
- **Saves nothing.** Pages load in a non-persistent `WKWebView` data store, so
  no history, cookies, or site data survive the session.
- **Simple gestures.** Pull down to refresh; swipe in from the right edge to
  close the page.
- SwiftUI + WKWebView, iPhone and iPad.

## Building

Requirements: Xcode 27 or later, iOS 26.1+.

1. Open `Miru Browser.xcodeproj`.
2. Change the signing team and bundle identifier to your own, then build the
   **Miru Browser** scheme.

The default-browser entitlement (`com.apple.developer.web-browser`) is granted
by Apple per developer account. Builds signed with your own team won't carry it
unless Apple grants it to you — remove it from `Miru Browser/Miru Browser.entitlements`
if signing fails. Everything else works without it.

To open a page in a simulator build without the default-browser role, use the
`miru://` scheme:

```sh
xcrun simctl openurl booted "miru://open?url=https://example.com"
```

## Repository layout

- `Miru Browser/` — the app (views, models, ad-blocking services, bundled resources)
- `marketing/` — App Store screenshots and the scripts that generate them; see
  [`marketing/README.md`](marketing/README.md)

## Contributing and feedback

Issues and pull requests are welcome. Miru is deliberately small, so for new
features it's worth opening an issue first. For anything else, email
[kmdutra@gmail.com](mailto:kmdutra@gmail.com).

## License

The source code is released under the [MIT License](LICENSE).

## Trademarks

"Miru", the Miru logo, and the Miru app icon are trademarks of Kevin Dutra and
are **not** covered by the MIT License. You're welcome to fork and build on this
code, but if you distribute your own version — on the App Store or elsewhere —
please give it a different name and icon so it isn't confused with Miru.

## Acknowledgements

Ad blocking uses [EasyList](https://easylist.to/), bundled at
`Miru Browser/Resources/easylist.txt` under the
[Creative Commons Attribution-ShareAlike 3.0](https://creativecommons.org/licenses/by-sa/3.0/)
license. Thanks to the EasyList authors.

The home screen's night sky places real stars as seen from New York City, using
the [Yale Bright Star Catalog](https://cdsarc.cds.unistra.fr/viz-bin/cat/V/50)
(5th revised ed., Hoffleit & Warren 1991) via the CDS VizieR service, bundled at
`Miru Browser/Resources/stars.csv`.
