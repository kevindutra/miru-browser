# Miru Browser

A minimal, calm iOS browser. Miru opens links, blocks ads, and gets out of the
way — no tabs, no accounts, no data collected.

- Opens any http/https link as your default browser
- Built-in ad blocking (EasyList, updated in the background)
- A single configurable bookmark on the home screen
- SwiftUI + WKWebView, iPhone and iPad

## Building

Requirements: Xcode 27 or later, iOS 26.1+.

1. Open `Miru Browser.xcodeproj`.
2. Change the signing team and bundle identifier to your own, then build the **Miru Browser** scheme.

The default-browser entitlement (`com.apple.developer.web-browser`) is granted
by Apple per developer account. Builds signed with your own team won't carry it
unless Apple grants it to you — remove it from `Miru Browser/Miru Browser.entitlements`
if signing fails. Everything else works without it.

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
