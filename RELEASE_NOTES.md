# SketchUp Dark Mode v1.1.2 📋

A diagnostics, stability, and transparency update featuring real-time diagnostic file logging, optional tooltip styling, and versioned package downloads.

---

### 🌟 What's New in v1.1.2

- 📋 **Automated Diagnostic File Logging (`sketchup_dark_mode.log`)**:
  - Automatically records step-by-step startup, DWM titlebar, Qt Fiddle initialization, palette updates, and viewport state changes.
  - Every log entry is **immediately flushed to disk** (`File#flush`), ensuring that if a crash or BugSplat occurs, the exact line executed prior to the crash is preserved.
  - Added **"View Diagnostic Log File"** in *Extensions -> Dark Mode -> View Diagnostic Log File* for 1-click inspection, or locate it at:
    `%APPDATA%\SketchUp\SketchUp <year>\SketchUp\sketchup_dark_mode.log`
- 💬 **Optional Tooltip Styling (Experimental, Off by Default)**:
  - Tooltip palette customization is now an optional user toggle in **Dark Mode Settings** (`style_tooltips: false` by default).
  - When disabled (default), the extension **completely bypasses** all low-level Fiddle calls to `QToolTip::setPalette` and `QToolTip::palette()`, eliminating any possibility of tooltip-related memory corruption or hover crashes.
  - Safe Qt CSS rules for `QToolTip` remain active in `dark_theme.qss`.
- 🏷️ **Versioned `.rbz` Packages**:
  - Releases now provide both `sketchup_dark_mode_v1.1.2.rbz` and `sketchup_dark_mode.rbz` for easier version tracking and manual archive management.
- 🧱 **Stable AppObserver Baseline**:
  - Maintained the proven `DarkModeAppObserver` architecture with a safe 1.0s initialization timer, preventing startup event loop deadlocks.

---

### 📦 Installation
1. Download **`sketchup_dark_mode_v1.1.2.rbz`** (or `sketchup_dark_mode.rbz`) from Assets below.
2. In SketchUp, open **Extensions** -> **Extension Manager**.
3. Click **Install Extension** and select the downloaded file.
4. Click the moon toggle button on the **Dark Mode** toolbar to activate!

---

### 🛠️ Help Us Debug / Community Feedback
If you encounter any crash or unexpected behavior:
1. Open `%APPDATA%\SketchUp\SketchUp <year>\SketchUp\sketchup_dark_mode.log` (or *Extensions -> Dark Mode -> View Diagnostic Log File*).
2. Copy and paste the log contents into the [SketchUp Community Forum thread](https://forums.sketchup.com/t/can-dark-mode-extension-be-released/349839).
3. If a BugSplat window appears, please submit it and share your **Crash #ID**!

---

### ⚠️ Disclaimer & Research Notice
This project is an independent community proof-of-concept (PoC) developed for educational and interoperability research purposes. It is **not** affiliated with, endorsed by, or supported by Trimble Inc. Use at your own risk.
