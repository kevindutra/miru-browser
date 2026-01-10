---
name: Floating Nav Islands
overview: "Redesign the navigation bar from a single full-width glass panel into two separate floating elements: a compact back/forward pill on the left and a separate 3-dot menu button on the right."
todos:
  - id: nav-pill
    content: Create compact glass pill with back/forward buttons
    status: completed
  - id: menu-button
    content: Create standalone floating glass menu button
    status: completed
  - id: layout
    content: Update outer HStack layout with Spacer between elements
    status: completed
---

# Floating Navigation Islands

## Overview

Replace the current full-width bottom navigation bar with two separate floating glass elements matching your mockup design.

## Current vs New Layout

```javascript
CURRENT:                          NEW (from mockup):
┌─────────────────────────────┐   
│  ←     →          ⋯        │   ┌──────────┐         ┌───┐
└─────────────────────────────┘   │  ←    →  │         │ ≡ │
      (full-width panel)          └──────────┘         └───┘
                                  (compact pill)   (menu btn)
```



## Changes

### 1. Update NavigationBar.swift

Restructure `glassPanel` to create two separate floating elements:

- **Navigation Pill** (left): Compact glass capsule with back/forward buttons side-by-side, no spacers between them
- **Menu Button** (right): Standalone glass circle with 3-dot icon (using `ellipsis` SF Symbol)

The outer container will use an `HStack` with `Spacer()` between the two elements to push them to opposite edges.

```swift
// New structure in NavigationBar.swift
HStack {
    // Left: compact back/forward pill
    HStack(spacing: 8) {
        GlassNavButton(icon: "arrow.left", ...)
        GlassNavButton(icon: "arrow.right", ...)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background { /* glass capsule */ }
    
    Spacer()
    
    // Right: floating menu button
    menuButton
        .padding(8)
        .background { /* glass circle */ }
}
```



### 2. Update ContentView.swift

Adjust the padding in `portraitBrowserView` and `landscapeBrowserView` to give appropriate spacing from screen edges (around 16-20pt horizontal padding).

### 3. Visual Details

- Use `Capsule()` shape for the navigation pill
- Use `Circle()` shape for the menu button background
- Both get `.fill(.ultraThinMaterial)` and `.glassEffect()` for consistency
- Change arrow icons from `chevron.left`/`chevron.right` to `arrow.left`/`arrow.right` to match your mockup

## Files to Modify