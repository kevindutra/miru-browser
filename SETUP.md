# Miru Browser Setup Guide

## Project Structure

The project has been set up with the following components:

```
Miru Browser/
├── Miru_BrowserApp.swift       # App entry point with URL handling
├── ContentView.swift           # Main browser view with empty state
├── Info.plist                  # URL scheme configuration
├── Views/
│   ├── WebView.swift           # WKWebView wrapper
│   └── NavigationBar.swift     # Bottom navigation toolbar
├── Services/
│   ├── AdBlocker.swift         # Content blocking manager
│   ├── FilterListParser.swift  # EasyList format parser
│   └── FilterUpdateService.swift # Background filter updates
├── Models/
│   └── BrowserState.swift      # Observable browser state
└── Resources/
    └── easylist.txt            # Bundled EasyList filter rules
```

## Adding the Share Extension Target (Required Manual Step)

The Share Extension files have been created in `Share Extension/` but the target must be added manually in Xcode:

### Step 1: Add Share Extension Target

1. Open `Miru Browser.xcodeproj` in Xcode
2. Go to **File > New > Target...**
3. Select **iOS > Share Extension**
4. Click **Next**
5. Configure:
   - **Product Name:** `Share Extension`
   - **Team:** Select your team
   - **Bundle Identifier:** `miru.Miru-Browser.Share-Extension`
   - **Language:** Swift
6. Click **Finish**
7. If prompted to activate the scheme, click **Cancel** (we'll configure manually)

### Step 2: Replace Generated Files

1. Delete the auto-generated files in the new `Share Extension` folder in Xcode
2. Drag the existing `Share Extension` folder from Finder into Xcode
3. Make sure to:
   - Check "Copy items if needed"
   - Select "Create groups"
   - Add to target: "Share Extension"

### Step 3: Configure the Share Extension

1. Select the `Share Extension` target in Xcode
2. Go to **Signing & Capabilities**
3. Set the same Team as the main app
4. Go to **Build Settings**
5. Set **Info.plist File** to `Share Extension/Info.plist`

### Step 4: Configure App Groups (Optional but Recommended)

For better communication between the main app and extension:

1. Select **Miru Browser** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Create a new group: `group.miru.Miru-Browser`
6. Repeat for the **Share Extension** target

## Testing the App

### URL Scheme Testing

Test the URL scheme by opening Safari and navigating to:
```
miru://open?url=https://example.com
```

Or use the terminal:
```bash
xcrun simctl openurl booted "miru://open?url=https://apple.com"
```

### Share Extension Testing

1. Build and run the app on a device/simulator
2. Open Safari and navigate to any website
3. Tap the Share button
4. Select "Miru" from the share sheet
5. The page should open in Miru Browser

## Features

- **Ad Blocking:** Uses EasyList-based content blocking with ~150 common ad network rules bundled. Auto-updates weekly.
- **URL Scheme:** Opens links via `miru://open?url=<encoded-url>`
- **Share Extension:** Accepts URLs from iOS Share Sheet
- **Navigation:** Back, Forward, Refresh buttons
- **No Data Storage:** No history, bookmarks, or cookies persisted

## Updating EasyList

The app checks for EasyList updates weekly. To force an update or use the full EasyList:

1. Download the full EasyList from: https://easylist.to/easylist/easylist.txt
2. Replace `Resources/easylist.txt` with the downloaded file
3. Rebuild the app

Note: WebKit limits content blocking to 50,000 rules, so the parser prioritizes the most impactful rules.

