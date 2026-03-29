**Astral Copy Project Brief for Claude (and other AI coding assistants)**

**Last updated:** March 29, 2026
**Project name:** AstralCopy
**Type:** macOS Menu Bar App (SwiftUI + AppKit)
**Goal:** A beautiful, lightweight clipboard history manager that optionally **overrides Cmd+V** to show a picker with the last 50 copied items (text + images).

---

### 1. Core Philosophy (never forget this)
- Normal **Cmd+C** must **always** work exactly as the system expects.
- **Cmd+V** can be overridden to show the history list (advanced mode).
- The app must feel native, minimal, and respectful of macOS conventions.
- First-time user experience must be **frictionless** — explain permissions clearly and guide the user directly to the right System Settings panes.
- Automatic launch at login is enabled by default and must be toggleable.
- Resource usage must stay extremely low (polling every 500 ms is acceptable; no background processes that drain battery).
- Localization : default is en (also add fr, es, de)

---

### 2. Architecture & Key Files
AstralCopy/
├── AstralCopyApp.swift                 ← @main entry point
├── ClipboardService.swift              ← Core: monitors pasteboard, stores history (text + images)
├── EventTapManager.swift               ← CGEventTap for true Cmd+V override
├── HistoryManager.swift                ← @MainActor singleton that shows the history UI
├── HistoryView.swift                   ← SwiftUI list with images, previews, tap-to-paste
├── PermissionsManager.swift            ← First-launch onboarding + TCC checks
├── LaunchSettings.swift                ← SMAppService for login item
├── Assets.xcassets
└── Info.plist

**Important singletons (all @MainActor where needed):**
- `ClipboardService.shared`
- `EventTapManager.shared`
- `HistoryManager.shared`
- `PermissionsManager.shared`
- `LaunchSettings.shared`

---

### 3. How the Magic Works

1. **Clipboard monitoring**
   Timer + `NSPasteboard.changeCount` (no official notification exists).
   Supports `.string`, `.png`, `.jpg`, `.webp`, `.gif`, `.tiff`.

2. **Cmd+V override**
   `CGEvent.tapCreate` + `keyCode == 9` + `.maskCommand`.
   If detected → `HistoryManager.shared.showHistory()` and return `nil` to block the event.

3. **Paste simulation**
   After user selects an item → write to pasteboard → small delay → `CGEvent` simulating Cmd+V so the frontmost app receives the paste.

4. **Permissions**
   - Accessibility (`AXIsProcessTrustedWithOptions`)
   - Input Monitoring (`IOHIDRequestAccess`)
   First launch shows a clean onboarding sheet with direct links to the exact System Settings panes.

5. **Launch at Login**
   Modern `SMAppService.mainApp.register()` / `unregister()` (macOS 13+).
   Controlled via `@AppStorage("launchAtLogin")`.

---

### 4. Coding Standards & Preferences (follow these)

- Use **Swift 6** concurrency (`@MainActor` where UI or TCC is involved).
- All managers are singletons with `static let shared`.
- Prefer SwiftUI for all UI (including the history list and menu bar).
- If possible do not use heavy dependencies.
- Never use `UserDefaults` for the history array — use `Codable` + JSON in Application Support for persistence (add this in v1.1 if not already present).
- Comments should explain **why**, not what.
- All public APIs must be thread-safe where appropriate.
- When adding new pasteboard types (RTF, URLs, files…), extend the `Content` enum cleanly.

---

### 5. Feature Roadmap (in order of priority)

**v1.0 (current)**
- Text + image history
- Cmd+V override
- First-launch permission onboarding
- Auto Launch at login
- Menu bar extra

**v1.1**
- Persistent storage (JSON)
- Search/filter in history
- Keyboard navigation (↑↓ + Enter)
- Manage password fields (check for `.secureText` or specific pasteboard types) to display only the 3 first letters and hide the following BUT when copying it should copying the right letters

**v2.0**
- Floating popover near cursor instead of WindowGroup
- Support more types (files, URLs, RTF, colors)
- Custom hotkey fallback (Cmd+Shift+V)
- Dark mode perfection + animations

---

### 6. How to Test

1. Build & run in Xcode.
2. On first launch → onboarding must appear automatically.
3. Grant both permissions → Cmd+V should now open the history list.
4. Copy text and images → they must appear instantly.
5. Toggle "Launch at login" → verify in System Settings → Login Items.
6. Restart macOS → app must auto-launch.

**Pro tip for debugging EventTap:**
If the tap stops working after macOS update, the app must be re-code-signed:
```bash
codesign -f -s - /path/to/AstralCopy.app
```

### 7. What to Never Do
- Do not block Cmd+C.
- Do not request more permissions than absolutely necessary.
- Do not store history in UserDefaults (too small for images).
- Do not show a dock icon (pure menu-bar app).
- Do not use deprecated NSPasteboard methods.
