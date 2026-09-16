# SketchUp Dark Mode v1.1.2 🛡️

Critical fix for UI styling crash and modern `AppObserver` refactoring.

---

### 🌟 What's Changed in v1.1.2
- **Fixed `style_ui` Tooltip Crash**: Removed dangerous `QToolTip::setPalette` and `QToolTip::palette` native Fiddle bindings which caused memory corruption and immediate BugSplat when hovering over buttons. Tooltips are now styled natively and safely via Qt CSS (`QToolTip { ... }`).
- **Sanitized QSS Property Selectors**: Removed `qproperty-icon` and `[toolTip*="..."]` dynamic property selectors on close buttons, preventing Qt stylesheet property resolution crashes.
- **Idiomatic `AppObserver` Architecture**: Adopted Dan Rathbun's recommended architecture attaching `Main` directly as the `AppObserver` using `onExtensionsLoaded`, ensuring styles are applied cleanly after all other extensions finish loading.

---

### 📦 Installation
1. Download **`sketchup_dark_mode.rbz`** from the Assets below.
2. In SketchUp, open: **Extensions** -> **Extension Manager**.
3. Click **Install Extension** and select `sketchup_dark_mode.rbz`.
4. Click the moon toggle button on the **Dark Mode** toolbar to activate!

---

### ⚠️ Disclaimer & Research Notice
This project is an independent community proof-of-concept (PoC) developed for educational and interoperability research purposes. It is **not** affiliated with, endorsed by, or supported by Trimble Inc. Use at your own risk.


