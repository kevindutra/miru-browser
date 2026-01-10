---
name: Build and Run Miru Browser
overview: Build the Miru Browser iOS app from command line and launch it in the iPhone simulator. The project is already set up with all necessary Swift files, Xcode project configuration, and has available simulator devices.
todos:
  - id: boot-simulator
    content: Boot iPhone 17 Pro simulator and open Simulator app
    status: completed
  - id: build-app
    content: Build Miru Browser scheme for iOS Simulator using xcodebuild
    status: completed
    dependencies:
      - boot-simulator
  - id: install-launch
    content: Install and launch the app on the booted simulator
    status: completed
    dependencies:
      - build-app
  - id: verify-app
    content: Test the app by opening a URL via the miru:// scheme
    status: completed
    dependencies:
      - install-launch
---

# Build and Preview Miru Browser in iOS Simulator

## Project Overview

The Miru Browser is a fully configured iOS Swift app with:

- Main app target: `Miru Browser`
- Share Extension target: `Share Extension`  
- Scheme: `Miru Browser`
- Available simulators: iPhone 17 Pro, iPhone 17, iPhone Air, iPads (iOS 26.1/26.2)

## Build and Run Steps

### Step 1: Boot the iOS Simulator

Launch an iPhone 17 Pro simulator (UDID: `0D7B55BA-D351-4742-89FF-40C3C52C41D1`) which was last used and has cached data:

```bash
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator
```



### Step 2: Build the App for Simulator

Build the `Miru Browser` scheme for the iOS Simulator using `xcodebuild`:

```bash
cd "/Users/kevindutra/Code/Miru Browser"
xcodebuild -scheme "Miru Browser" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -derivedDataPath build \
  build
```



### Step 3: Install and Launch the App

Install the built app on the simulator and launch it:

```bash
xcrun simctl install booted "build/Build/Products/Debug-iphonesimulator/Miru Browser.app"
xcrun simctl launch booted "miru.Miru-Browser"
```



### Step 4: Verify the App

Once launched, the app should display the empty browser state. To test URL loading:

```bash
xcrun simctl openurl booted "miru://open?url=https://apple.com"
```



## Expected Output

The Miru Browser app will launch in the iPhone 17 Pro simulator showing: