# SketchUp Dark Mode v1.1.1 🛡️

A critical stability and crash prevention patch for **SketchUp Dark Mode**.

---

### 🌟 What's Changed in v1.1.1
- **Safe Installation (No Auto-Crash)**: Dark mode is now disabled by default on initial installation (`dark_mode_enabled: false`). Installing the `.rbz` is completely benign, registers cleanly, and will not inject Qt styles or DWM window changes while Extension Manager is running.
- **Dynamic Version Config Path**: Replaced hardcoded `SketchUp 2025` directory with dynamic detection from `Sketchup.find_support_file('Plugins')`, preventing path errors across different versions.
- **DWM & EnumWindows Safety Guards**: Added isolated exception handling inside each window iteration in `EnumWindows` and guarded `apply_dark_to_hwnd` against null/invalid window handles.
- **Delayed Startup Initialization**: Startup timer increased to 1.0s to allow SketchUp's core plugins, dialogs, and splash screen to fully finish booting before applying styles.
- **Emergency Recovery Guide**: Added comprehensive troubleshooting steps to the README (Dan Rathbun's `.rb!` rename method and config JSON toggling).

---

### 📦 Installation
1. Download **`sketchup_dark_mode.rbz`** from the Assets below.
2. In SketchUp, open: **Extensions** -> **Extension Manager**.
3. Click **Install Extension** and select `sketchup_dark_mode.rbz`.
4. Click the moon toggle button on the **Dark Mode** toolbar to activate!

---

### ⚠️ Disclaimer & Research Notice
This project is an independent community proof-of-concept (PoC) developed for educational and interoperability research purposes. It is **not** affiliated with, endorsed by, or supported by Trimble Inc. Use at your own risk.

