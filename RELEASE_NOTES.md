# SketchUp Dark Mode v1.1.4 🚀

A critical styling and usability update fixing the Measurements / Value Control Box (VCB) active drawing tool white background, making dimension inputs dark and readable at all times, and fixing settings dialog callback visibility.

---

### 🌟 What's New in v1.1.4

- 📏 **Dark Measurements / VCB (Value Control Box) Input Fixed**:
  - Resolved an issue where selecting an active drawing or measuring tool (e.g. Tape Measure, Line, Rectangle) caused the bottom-right Measurements input box to turn bright white with white text, making typed dimensions invisible.
  - **Dynamic In-Memory White Suppression (`VcbStyler`)**: SketchUp's native Qt widget `StatusVCBEdit` contained hardcoded C++ paint logic in `paintEvent` that filled the background with `Qt::white` whenever a tool became active, bypassing all standard QSS stylesheet rules. The new `VcbStyler` module dynamically patches the conditional branch to consistently use the dark window palette role (`Role 10 / #252526`), keeping the box dark without interfering with input handling.
  - Restores stock SketchUp behavior completely upon switching back to light mode.
- 🎨 **Enhanced Measurements QSS Styling**:
  - Added targeted QSS rules covering `StatusVCBEdit`, `CToolBarVCBValueButton`, `VCBValueButton`, `QStatusBar QLineEdit`, `QLineEdit#vcb`, `QWidget#vcb`, and `[class*="StatusVCB"]`.
  - Focused inputs feature a `#1e1e1e` dark background with a `#007acc` blue accent border.
  - Measurement status labels ("Długość" / "Measurements") now have a transparent background to seamlessly blend into the status bar.
- 🐛 **Settings UI Callback Visibility Fix**:
  - Made `update_ui_elements` a public module function on `SketchupDarkMode::Main`, resolving `NoMethodError: private method update_ui_elements called` when saving or closing the Settings dialog.
- 🔍 **Compatibility Verified**:
  - Fully tested and verified on **SketchUp Pro 2026 (build 26.2.243)** and **SketchUp Pro 2025 (build 25.0.571)**.

---

### 📦 Installation
1. Download **`sketchup_dark_mode_v1.1.4.rbz`** (or `sketchup_dark_mode.rbz`) from Assets below.
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
