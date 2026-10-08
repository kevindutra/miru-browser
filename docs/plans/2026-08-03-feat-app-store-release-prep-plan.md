---
title: "feat: App Store release prep — remove IAP, restore browser entitlement, ship v1.0"
type: feat
status: active
date: 2026-08-03
---

# 🚀 App Store Release Prep: Remove IAP, Restore Browser Entitlement, Ship v1.0

## Overview

Miru Browser (minimal SwiftUI iOS browser, main app + Share Extension) has been idle since Jan 11, 2026. The goal is the **fastest safe path to App Store release**: triage ~7 months of uncommitted work, remove all in-app-purchase code, verify the app on the latest simulator, and submit a new build. Apple has since granted the `com.apple.developer.web-browser` managed entitlement, which the uncommitted work re-adds.

## Problem Statement / Motivation

- The working tree mixes **keeper work** (browser entitlement, new app icons/logo, empty-state UI redesign) with **payment work to drop** (a $4.99 "Remove Globe Button" non-consumable IAP, product ID `feat001`).
- The last commit (`339677f`, "changes to get first review approved") *removed* the entitlement to pass first review; the uncommitted change re-adds it now that it's granted.
- Adding the entitlement triggers browser-specific review criteria the app doesn't obviously meet today (see Decisions).

## Current State (verified 2026-08-03)

**Toolchain:** Xcode 26.6 (17F113) installed — satisfies Apple's April 2026 requirement (Xcode 26 / iOS 26 SDK minimum for submissions). Simulators: iOS 26.1 and 26.2 runtimes; target **iPhone 17 Pro (iOS 26.2)**.

**Project:** `objectVersion 77` with filesystem-synchronized groups — files on disk are auto-included in targets; **no pbxproj edits needed for file removal**. `MARKETING_VERSION = 1.0`, automatic signing, team `D6R4M9FM42`. `ExportOptions.plist` already set up (`app-store-connect`, `manageAppVersionAndBuildNumber = true`).

**Already done (no work needed):**
- ✅ `PrivacyInfo.xcprivacy` exists and is correct (UserDefaults / `CA92.1`, no tracking, no data collected)
- ✅ Info.plist has no entitlement-prohibited keys (`NSLocationWhenInUseUsageDescription` is the allowed variant; camera/mic are fine)
- ✅ `ITSAppUsesNonExemptEncryption = false`; HTTP/HTTPS `CFBundleURLTypes` declared (required for default-browser role)
- ✅ Share Extension activation rule fixed (no `TRUEPREDICATE`)
- ✅ Privacy policy created/hosted (per `.cursor/plans/app_store_submission_6b20f94d.plan.md`)

### Uncommitted work triage

| Change | Verdict |
|---|---|
| `Miru Browser.entitlements` — adds `com.apple.developer.web-browser` | **KEEP** (the point of the release) |
| App icon swap + `Logo.imageset` (staged) | **KEEP** (verify tinted variant; rename `Dark (1) 1.png`-style files) |
| `ContentView.swift` empty-state redesign (centered logo, corner buttons) | **KEEP** (drop only the purchase gate) |
| `xcshareddata/` shared schemes | **KEEP** (strip StoreKit config references) |
| `Services/StoreManager.swift`, `StoreKitConfig.storekit` | **DELETE** |
| IAP code in `SettingsView.swift`, `Settings.swift`, `ContentView.swift` | **REMOVE** (surgical — see Phase 2) |
| `.cursor/plans/*.plan.md` frontmatter churn | Commit or discard — no content change |
| `xcuserdata/.../xcschememanagement.plist` | **Don't commit**; `git rm --cached` it (gitignore already covers the pattern) |

⚠️ **`git checkout` is NOT a safe removal strategy** — the same modified files contain keeper work. Surgical edits only.

## Decisions (RESOLVED 2026-08-03)

### Decision 1: Launch-UI criteria → ✅ satisfied via the single curated bookmark (ship as-is)
The entitlement's review criteria require, at launch, at least one of: **a URL text field, internet search tools, or curated bookmarks** ([Apple: Preparing your app to be the default web browser](https://developer.apple.com/documentation/Xcode/preparing-your-app-to-be-the-default-browser)). **Resolution: Miru meets this via curated bookmarks** — the user-configurable default-site bookmark, surfaced at launch as the globe button on the empty state. The entitlement was granted on this basis; no URL field will be added.

Implications to carry through the plan:
- The globe button is now the app's **qualifying review affordance** — `showDefaultSiteButton` defaults to `true`, so a fresh install (what a reviewer sees) shows it. Don't change that default.
- Review Notes (Phase 7) must spell out the rationale: launch UI provides a curated bookmark (user-configurable in Settings), and the app opens arbitrary http/https URLs from any app as the default browser.
- The "schemeless URL silently no-ops" edge case (below) is now worth fixing while editing SettingsView — a dead qualifying affordance during review would be bad. Small fix: prepend `https://` when the entered default-site URL has no scheme.

### Decision 2: Share Extension → ✅ cut from this release
`Share Extension/ShareViewController.swift` is the unmodified Xcode template — "Post" does nothing with the shared URL (Guideline 2.1 rejection vector). **Resolution: remove the Share Extension from the release**; re-add when actually implemented. The in-app share *sheet* (menu → Share) is unaffected and keeps working. Work items are in Phase 3.

## Implementation Phases

### Phase 1: ASC / account preflight (do first — 7-month staleness)
Human steps in the developer portal / App Store Connect; any one of these can silently block upload:

- [ ] Apple Developer Program membership active; **pending agreements accepted** in ASC (blocks uploads silently)
- [ ] App ID `miru.Miru-Browser` shows the **Default Browser capability enabled** (Certificates, Identifiers & Profiles → Identifiers → Additional Capabilities). The grant alone isn't enough; profiles generated before enablement won't contain the entitlement
- [ ] Distribution certificate valid (certs last 1 year — one from early 2026 may be near expiry; automatic signing can mint a new one)
- [ ] **Check version 1.0's state in ASC**: if 1.0 was released ("Ready for Sale"), create version 1.0.1/1.1 in ASC and bump `MARKETING_VERSION` to match; if 1.0 is still in "Prepare for Submission"/rejected, reuse it. Record the decision. (`manageAppVersionAndBuildNumber` covers build numbers only.)
- [ ] **Delete IAP product `feat001`** in ASC if it was created (deletable while never-approved), or confirm it's detached from the version submission; scrub metadata of purchase mentions. Lingering ghost IAPs have caused 2.1 rejections ([forum thread](https://developer.apple.com/forums/thread/706415))

### Phase 2: Remove all payment work (surgical, no pbxproj edits)

- [x] Delete `Miru Browser/Services/StoreManager.swift` (entire file is IAP)
- [x] Delete `Miru Browser/StoreKitConfig.storekit` — ⚠️ currently **bundled into the .app as a resource** by the synchronized group; deleting fixes that too
- [x] `Miru Browser/Views/SettingsView.swift`: remove `import StoreKit` (line 8); the six purchase `@State` vars + `storeManager` property (lines 12–23); **unwrap** the `if !settings.hasRemovedGlobeButton { … } else { … }` around the whole Form (lines 29–127) keeping the Home Button + Default Site URL sections; remove the "In-App Purchase" section, "Purchase Status" section, the Restore alert + `.task { storeManager.loadProducts() }` modifiers (lines 138–145), and `purchaseRemoveGlobe()` / `restorePurchases()` (lines 150–178)
- [x] `Miru Browser/Models/Settings.swift`: remove `hasRemovedGlobeButtonKey` (line 14), the `hasRemovedGlobeButton` property (lines 28–34), and its init load (line 39)
- [x] `Miru Browser/ContentView.swift:266`: change `if settings.showDefaultSiteButton && !settings.hasRemovedGlobeButton` → `if settings.showDefaultSiteButton` (keep the rest of the new empty-state layout)
- [x] `Miru Browser.xcodeproj/xcshareddata/xcschemes/Miru Browser.xcscheme:43`: delete the `storeKitConfigurationFileReference` attribute
- [x] `Miru Browser.xcodeproj/xcshareddata/xcschemes/Share Extension.xcscheme:60–62`: delete the `<StoreKitConfigurationFileReference>` element
- [x] Verify: `grep -ri "StoreKit\|StoreManager\|hasRemovedGlobeButton\|feat001" "Miru Browser/" "Share Extension/" "Miru Browser.xcodeproj/xcshareddata/"` returns nothing

Leftover `hasRemovedGlobeButton` values in dev-device UserDefaults are harmless (nothing reads the key after removal; the app never shipped, so no real users).

### Phase 3: Remove Share Extension + harden the bookmark + asset check

- [x] **Remove the Share Extension target** from `Miru Browser.xcodeproj` (Xcode: delete target — removes the embed build phase; the `PBXFileSystemSynchronizedRootGroup` for `Share Extension/` goes with it). Delete `Miru Browser.xcodeproj/xcshareddata/xcschemes/Share Extension.xcscheme`. Keep the `Share Extension/` source folder in git history (it's reference material for the future implementation) or delete it — either way it must not ship
- [x] **Bookmark hardening** (the globe button is now the review-qualifying affordance): in `SettingsView.swift`, normalize the default-site URL on entry — prepend `https://` when no scheme is present — so a reviewer typing `example.com` doesn't get a silently dead button. Do **not** change `showDefaultSiteButton`'s default of `true`
- [x] App icon: confirm `Dark (1) 1.png` is a genuine **tinted** (grayscale) variant, not a dark duplicate; rename the `(1)`-suffixed files to sane names (`Light.png`/`Dark.png`/`Tinted.png`) updating `Contents.json`
- [x] `Logo.imageset`: verify the SVG renders crisply at 120×120pt; add "Preserve Vector Data" (`preserves-vector-representation`) if blurry

### Phase 4: Build & verify on latest simulator

```bash
xcodebuild -project "Miru Browser.xcodeproj" -scheme "Miru Browser" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build
```

- [x] Debug build + launch on iPhone 17 Pro — note: Xcode 26.6 required downloading the iOS 26.5 platform; verified on **iOS 26.5** (newer than planned 26.2)
- [x] Settings: Home Button toggle + Default Site URL field work with no IAP remnants visible
- [x] Empty state: logo centered, globe (bottom-left) loads default site, gear (bottom-right) opens settings
- [x] **Cold-start and warm-start deep link**: `xcrun simctl openurl booted "https://example.com"` and an http link tapped from Notes — both route into the browser (`onOpenURL` → `pendingExternalURL` path)
- [ ] iOS Settings → Apps → Default Apps → Browser lists Miru (entitled builds only); set it and confirm links route to Miru. Note: there is **no in-app "set default" prompt** — none exists in the code; don't test for one
- [x] iPad simulator smoke test (iPad Pro 13" M5, iOS 26.5 — WKWebView page load verified) (`TARGETED_DEVICE_FAMILY = "1,2"` — reviewers may use iPad); check empty-state corners + landscape
- [ ] Airplane-mode launch doesn't hang (`FilterUpdateService.checkForUpdates()` runs at launch)
- [x] **Release configuration builds clean** (`-configuration Release`) before archiving
- [ ] One site requesting camera/mic/location permission behaves sanely

### Phase 5: Commit the cleaned work

- [x] `git rm --cached "Miru Browser.xcodeproj/xcuserdata/kevindutra.xcuserdatad/xcschemes/xcschememanagement.plist"` (pattern already gitignored)
- [x] Commit keeper work: entitlement, icons/logo, empty-state redesign, IAP removal, schemes, this plan — logically grouped commits (e.g., `feat: restore default-browser entitlement`, `feat: redesign empty state with logo`, `chore: remove in-app purchase feature`)

### Phase 6: Archive, validate entitlements, upload

Simulator runs use *simulated* entitlements — **the archive is the first real test of the managed entitlement**. Archive early, not last.

```bash
xcodebuild -project "Miru Browser.xcodeproj" -scheme "Miru Browser" \
  -configuration Release -archivePath build/Miru.xcarchive archive
codesign -d --entitlements - "build/Miru.xcarchive/Products/Applications/Miru Browser.app"
xcodebuild -exportArchive -archivePath build/Miru.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export
```

- [x] `codesign` output shows `com.apple.developer.web-browser` on the app (dev-signed archive verified 2026-08-03; embedded profile includes the entitlement)
- [x] Archived .app contains **no** `StoreKitConfig.storekit` and **no** `PlugIns/Share Extension.appex`
- [ ] If export fails with "profile doesn't include entitlement": re-check Phase 1 App ID capability, clear cached profiles (`~/Library/Developer/Xcode/UserData/Provisioning Profiles`), let Xcode re-fetch
- [ ] Upload succeeds (needs live Xcode ASC session or an API key via `-authenticationKeyPath`)

**Status 2026-08-03:** Archive succeeds; local `-exportArchive` (destination: export) fails with three account-side blockers, all matching Phase 1 predictions — resolve in this order, then re-run the export:
1. **"PLA Update available"** — accept the updated Program License Agreement at developer.apple.com / App Store Connect (blocks all profile generation and uploads)
2. **No "iOS Distribution" signing certificate** — expired; sign into Xcode → Settings → Accounts → Manage Certificates → create Apple Distribution (or via the portal)
3. **Store provisioning profile lacks the Default Web Browser capability** — regenerate after 1–2 (dev profile already includes it, so the App ID grant is in place)

### Phase 7: ASC metadata + submit

- [ ] **Regenerate screenshots** from the new UI — old ones show the pre-redesign empty state (Guideline 2.3 risk). Required: iPhone 6.9" + 6.5"; **iPad 13" required** while the app targets iPad
- [ ] Age rating questionnaire: unrestricted web access = **yes** (forces highest tier; the Jan rating may predate the entitlement — mismatch is a metadata rejection)
- [ ] App Privacy labels: "Data Not Collected" (matches the privacy manifest); remove any purchase-data declarations
- [ ] Description/keywords scrubbed of any IAP mention
- [ ] Review Notes: state that (1) the granted default-browser entitlement's launch-UI criterion is met via **curated bookmarks** — the user-configurable default-site bookmark shown as the globe button at launch, editable in Settings; (2) the app's use case is QR/link-opening as a clean default browser; (3) the app contains **no IAP** (cheap insurance against ghost-IAP confusion)
- [ ] Submit for review

## Acceptance Criteria

- [ ] Zero StoreKit/purchase references in sources, schemes, and the archived .app (grep + archive inspection above)
- [ ] App builds and runs on iPhone 17 Pro (iOS 26.2) and iPad simulators, Debug and Release
- [ ] Default-browser flow verified end-to-end: entitlement in signed archive, Miru selectable as default, external links open in Miru cold and warm
- [ ] Keeper work committed; no `xcuserdata`/build artifacts tracked
- [ ] Share Extension target removed; archived .app contains no appex
- [ ] Default-site URL entry normalizes schemeless input (`example.com` → `https://example.com`)
- [ ] Build uploaded to ASC and submitted with regenerated screenshots, corrected age rating, and Review Notes covering the curated-bookmark rationale + no-IAP statement

## Known Edge Cases (note-and-ship)

- `miru://open` without a `url` param silently no-ops (by design)
- Empty state ignores safe areas in landscape — visual check only
- ~~Schemeless default-site URL silently no-ops~~ → promoted to Phase 3 fix, since the bookmark is now the review-qualifying affordance

## Dependencies & Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Reviewer judges the single bookmark insufficient for the launch-UI criterion | Low–Medium (entitlement was granted on this design) | Review Notes rationale (Phase 7); fallback if rejected: add a minimal URL field and resubmit |
| Stale provisioning/agreements block archive/upload | Medium | Phase 1 preflight; archive early (Phase 6 before Phase 7 metadata work) |
| Ghost IAP `feat001` in ASC confuses review | Low–Medium | Delete in Phase 1; review note |
| Old screenshots ≠ new UI | Certain if unaddressed | Phase 7 regeneration |

## Sources & References

### Internal
- Uncommitted diff analysis: `Miru Browser/Views/SettingsView.swift`, `Miru Browser/Models/Settings.swift:28-34`, `Miru Browser/ContentView.swift:266`, `Miru Browser/Miru Browser.entitlements`
- Scheme StoreKit refs: `Miru Browser.xcodeproj/xcshareddata/xcschemes/Miru Browser.xcscheme:43`, `Share Extension.xcscheme:60-62`
- Prior submission checklist: `.cursor/plans/app_store_submission_6b20f94d.plan.md`
- Build/signing config: `ExportOptions.plist`, `Info.plist`, `Miru Browser.xcodeproj/project.pbxproj`
- Privacy manifest (already correct): `Miru Browser/PrivacyInfo.xcprivacy`

### External
- [Apple: Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) — Xcode 26 / iOS 26 SDK minimum since 2026-04-28 (installed Xcode 26.6 satisfies this)
- [Preparing your app to be the default web browser](https://developer.apple.com/documentation/Xcode/preparing-your-app-to-be-the-default-browser) — launch-UI criteria, prohibited Info.plist keys, no set-default prompt required
- [Provisioning with managed capabilities](https://developer.apple.com/help/account/reference/provisioning-with-managed-capabilities) — profiles must be regenerated after capability enablement
- [Forum: rejection for unused ASC IAP products](https://developer.apple.com/forums/thread/706415)
- [ASC Help: submitting IAPs](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
- [Required-reason APIs / privacy manifests](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

### Research provenance
Compiled with Claude Code from three research passes: repository/build-config analysis, 2026 App Store requirements verification (web), and a SpecFlow gap analysis of the release flow. Line numbers verified against the working tree on 2026-08-03.
