# ClickType

A native macOS menu bar app that types the current plain-text clipboard as keyboard events when you click its menu bar icon.

## Run

1. Open `ClickType.xcodeproj` in Xcode and run the ClickType scheme, or open the supplied `ClickType.app`.
2. Copy text and place the caret in a text field. Then click the ClickType keycap icon in the menu bar.
3. On the first click, macOS may ask you to grant ClickType **Accessibility** access in System Settings → Privacy & Security → Accessibility. Grant access, then click the icon again. macOS may require an app restart after granting access.
4. Right-click (or Option-click) the menu bar icon for Accessibility options, **Run at Login**, or to quit. Move `ClickType.app` to Applications before enabling Run at Login so its path stays stable.

The app reads the clipboard when its menu bar icon is clicked. Ordinary clicks elsewhere do not trigger typing. Images and other non-text clipboard items are ignored. Some apps may ignore synthetic Unicode keyboard events, and secure or privileged fields may reject them.

## Build

Xcode 15 or later is required. The checked-in Xcode project is generated from `project.yml` with XcodeGen. The target uses AppKit, SwiftUI, Core Graphics, and ServiceManagement, has no third-party runtime dependencies, and does not use App Sandbox because it needs to send keystrokes to other apps. The release target uses bundle ID `dev.quackbyte.clicktype`, team `435MC3786D`, automatic signing, and version `1.0` (build `1`).

## Distribution

The current keyboard-typing feature requires Accessibility access and posts keyboard events to other apps. Apple requires App Sandbox for Mac App Store distribution and restricts assistive Accessibility APIs in sandboxed apps. Do not submit the current build to the Mac App Store or enable App Sandbox without first implementing and testing a compatible design. Developer ID distribution outside the store supports the current behavior; notarize release builds before sharing them.

Xcode Cloud can archive and sign macOS apps for Developer ID distribution. Its first workflow must be configured in Xcode and granted access to the Git repository. Commit and push the Xcode project settings before creating that workflow.
