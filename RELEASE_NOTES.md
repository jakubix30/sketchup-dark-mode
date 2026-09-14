# SketchUp Dark Mode v1.1.0 🚀

A major update for **SketchUp 2025** Dark Mode featuring crisp vector close icons, crystal-clear white tooltips, minimalist single-button toolbar, and comprehensive QSS documentation.

---

### 🌟 What's New in v1.1.0
- **Crisp White Vector Close Buttons (`[X]`)**: Replaced hardcoded charcoal (`#252A2E`) close icons with pure white vector SVG (`close_white.svg`) across all tray headers (`CPanelHeader #hide_button_`), dock widgets (`QDockWidget::close-button`), and KDDockWidgets headers.
- **Crystal-Clear Tooltips (`QToolTip`)**: Direct Fiddle binding to `QToolTip::setPalette(const QPalette&)` ensures every tooltip in toolbars, menus, and trays renders pure white text on dark graphite.
- **Minimalist 1-Button Toolbar**: Streamlined toolbar to a single toggle button (moon/sun icon). Full configuration remains easily accessible from the Extensions cascading menu.
- **Comprehensive QSS Documentation**: Added [QSS_DOCS.md](QSS_DOCS.md) and [QSS_DOCS_PL.md](QSS_DOCS_PL.md) detailing Qt 6 architecture in SketchUp 2025, widget selectors, 5 engineering gotchas, and theme authoring guides.
- **Improved Hot-Reload**: Live reloading now re-executes `qt_styler.rb` and `main.rb` alongside `dark_theme.qss` without restarting SketchUp.
- **Updated Preview Screenshot**: High-resolution screenshot reflecting modern UI refinements.
---

### 📦 Installation

1. Download **`sketchup_dark_mode.rbz`** from the Assets below.
2. In SketchUp 2025, open: **Extensions** -> **Extension Manager** (or **Rozszerzenia** -> **Menedżer rozszerzeń**).
3. Click **Install Extension** (**Zainstaluj rozszerzenie**) and select `sketchup_dark_mode.rbz`.
4. The extension will activate automatically and display the **Dark Mode** toolbar.

---

### ⚠️ Disclaimer & Research Notice

This project is an independent community proof-of-concept (PoC) developed for educational and interoperability research purposes. It is **not** affiliated with, endorsed by, or supported by Trimble Inc. Use at your own risk.
