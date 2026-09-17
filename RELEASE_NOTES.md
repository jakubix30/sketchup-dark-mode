# SketchUp Dark Mode v1.1.3 🚀

A major stability, theming, and compatibility update fixing dialog/tray background colors, eliminating restyling crashes, restoring crisp white vector close icons in trays, and introducing optional QSS panel styling.

---

### 🌟 What's New in v1.1.3

- 🎨 **Dark Dialog & Tray Backgrounds Fixed**:
  - Resolved an issue where modal dialogs (including Settings `UI.inputbox`) and default tray panels rendered with stark white backgrounds and white text.
  - Fixed a Ruby `NoMethodError` in the configuration handler that previously interrupted stylesheet application before CSS rules reached Qt.
  - Strengthened dark container styles (`#1e1e1e` / `#252526`) for `QDialog`, `QMessageBox`, `QInputDialog`, `QFileDialog`, and tray containers (`CDockingTray`, `KDDockWidgets`, `CMaterialBrowser`).
- 🛡️ **Sanitized QSS & Crash Prevention**:
  - Eliminated crashes during Qt's `setStyleSheet` by removing invalid `qproperty-icon` writes from Qt subcontrols (like `QDockWidget::close-button`) and removing recursive wildcard tooltip selectors.
  - Safe, standard CSS `image: url(...)` properties are now used for subcontrols.
- ⚙️ **Optional QSS Panel Styling Toggle (`apply_qss`)**:
  - Added a new setting: **Qt Stylesheet (QSS Panels)** in *Extensions -> Dark Mode -> Settings*.
  - When enabled (default), full CSS styling applies to dialogs, toolbars, and tray containers.
  - When disabled, the extension applies only Qt 6's dark system palette (`apply_dark_palette`), offering a 100% lightweight fallback with zero CSS overhead.
- ✖️ **Crisp White Vector Close Icons ([X]) Restored**:
  - Panel hide/close buttons across all tray containers (Entity Info, Materials, Components, Styles, Tags, etc.) now reliably render pure white vector icons (`close_white.svg`) across all language locales (Polish, English, and others).
  - All tray buttons and sidebar glyphs explicitly use pure white foregrounds (`#ffffff !important`).
- 🔍 **Compatibility Verified**:
  - Verified on **SketchUp Pro 2026 (build 26.2.243)** and **SketchUp 2025 (build 25.0.571)**.

---

### 📦 Installation
1. Download **`sketchup_dark_mode_v1.1.3.rbz`** (or `sketchup_dark_mode.rbz`) from Assets below.
2. In SketchUp, open **Extensions** -> **Extension Manager**.
3. Click **Install Extension** and select the downloaded file.
4. Click the moon toggle button on the **Dark Mode** toolbar to activate!

---

### 🛠️ Diagnostic Logs & Community Feedback
If you encounter any crash or unexpected behavior:
1. Open `%APPDATA%\SketchUp\SketchUp <year>\SketchUp\sketchup_dark_mode.log` (or *Extensions -> Dark Mode -> View Diagnostic Log File*).
2. Copy and paste the log contents into the [SketchUp Community Forum thread](https://forums.sketchup.com/t/can-dark-mode-extension-be-released/349839).
3. If a BugSplat window appears, please submit it and share your **Crash #ID**!

---

### ⚠️ Disclaimer & Research Notice
This project is an independent community proof-of-concept (PoC) developed for educational and interoperability research purposes. It is **not** affiliated with, endorsed by, or supported by Trimble Inc. Use at your own risk.
