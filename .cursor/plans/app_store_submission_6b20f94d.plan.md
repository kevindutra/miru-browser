---
name: App Store Submission
overview: Complete checklist for submitting Miru Browser to the App Store, covering Developer Program enrollment, project fixes, App Store Connect setup, and submission.
todos:
  - id: developer-enroll
    content: Enroll in Apple Developer Program ($99/year)
    status: pending
  - id: fix-share-extension
    content: Fix Share Extension activation rule (TRUEPREDICATE will be rejected)
    status: completed
  - id: privacy-policy
    content: Create and host Privacy Policy URL
    status: pending
  - id: screenshots
    content: Generate App Store screenshots from simulator
    status: in_progress
  - id: app-store-connect
    content: Create app record in App Store Connect with metadata
    status: pending
  - id: archive-upload
    content: Archive Release build and upload to App Store Connect
    status: pending
  - id: submit-review
    content: Submit app for Apple review
    status: pending
---

# App Store Submission Plan for Miru Browser

## Phase 1: Apple Developer Program Enrollment

You must enroll in the Apple Developer Program ($99/year) before you can submit apps:

1. Go to [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll)
2. Sign in with your Apple ID
3. Complete identity verification (may take 24-48 hours if manual review required)
4. Pay the $99 annual fee

Your project already has `DEVELOPMENT_TEAM = D6R4M9FM42` configured, so once enrolled, code signing should work automatically.

---

## Phase 2: Project Fixes Required

### 2.1 Fix Share Extension Activation Rule

Apple will reject `TRUEPREDICATE` in your Share Extension. Update [Share Extension/Info.plist](Share Extension/Info.plist) to specify a proper activation rule:

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
</dict>
```

### 2.2 Add App Privacy Manifest (Optional but Recommended)

Apple now recommends a `PrivacyInfo.xcprivacy` file for apps. Since Miru uses WKWebView and requests camera/microphone/location, you should declare these properly.

---

## Phase 3: Create Privacy Policy

Since your app requests camera, microphone, and location permissions, Apple requires a Privacy Policy URL.

**Option A**: Use a free privacy policy generator like [Termly](https://termly.io) or [PrivacyPolicies.com]

**Option B**: Host a simple privacy policy page on GitHub Pages, Notion, or your own website

Your privacy policy should explain:

- What data the app collects (website cookies via WKWebView, location when requested)
- That you don't collect or store personal data
- That websites viewed may have their own privacy policies
- Contact information

---

## Phase 4: Prepare App Store Screenshots

Screenshots are required for submission. Required sizes:

| Device Class | Resolution | Required |

|--------------|------------|----------|

| iPhone 6.9" | 1320 x 2868 | Yes |

| iPhone 6.5" | 1290 x 2796 | Yes |

| iPad Pro 13" | 2064 x 2752 | If supporting iPad |

I can help you generate these from the simulator using `xcrun simctl io booted screenshot`.

---

## Phase 5: App Store Connect Setup

After enrollment, create your app record:

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click "Apps" then "+" then "New App"
3. Fill in required information:

   - **Platform**: iOS
   - **Name**: Miru (or "Miru Browser")
   - **Primary Language**: English
   - **Bundle ID**: `miru.Miru-Browser`
   - **SKU**: `miru-browser-1` (any unique identifier)
   - **User Access**: Full Access

### 5.1 App Information Tab

- **Category**: Utilities
- **Content Rights**: Confirm you have rights to all content
- **Age Rating**: Complete the questionnaire (likely 4+ since no objectionable content)

### 5.2 Pricing and Availability

- Set price tier (Free)
- Select countries for availability

### 5.3 App Privacy

- Link your Privacy Policy URL
- Complete the App Privacy questionnaire:
  - Data types collected: None directly (websites may collect their own)
  - Tracking: No

### 5.4 Version Information

- **Screenshots**: Upload for each device size
- **Description**: Write compelling app description
- **Keywords**: browser, minimal, simple, clean, ad-blocker, privacy
- **Support URL**: Your website or GitHub repo URL
- **Marketing URL**: Optional

---

## Phase 6: Archive and Upload

Build and upload your app:

```bash
# Archive for distribution
xcodebuild -scheme "Miru Browser" \
  -configuration Release \
  -archivePath build/Miru.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/Miru.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

Or use Xcode: **Product > Archive**, then use Organizer to upload.

---

## Phase 7: Submit for Review

1. In App Store Connect, select your uploaded build
2. Add release notes (e.g., "Initial release")
3. Click "Submit for Review"
4. Apple typically reviews within 24-48 hours

---

## Summary Checklist

- [X] Enroll in Apple Developer Program
- [X] Fix Share Extension activation rule
- [X] Create and host Privacy Policy
- [ ] Create App Store screenshots
- [ ] Set up app record in App Store Connect
- [ ] Write app description and metadata
- [ ] Archive and upload build
- [ ] Submit for review