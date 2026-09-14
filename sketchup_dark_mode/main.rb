# frozen_string_literal: true

require 'sketchup.rb'

module SketchupDarkMode
  module Main
    extend self

    QSS_PATH = File.join(PLUGIN_DIR, 'sketchup_dark_mode', 'styles', 'dark_theme.qss')
    ICONS_DIR = File.join(PLUGIN_DIR, 'sketchup_dark_mode', 'icons')

    @app_observer = nil
    @toolbar = nil
    @cmd_toggle = nil
    @cmd_restore = nil

    class DarkModeAppObserver < Sketchup::AppObserver
      def onNewModel(model)
        Main.on_model_changed(model)
      end

      def onOpenModel(model)
        Main.on_model_changed(model)
      end

      def onActivateModel(model)
        Main.on_model_changed(model)
      end
    end

    def init
      # Automatyczna synchronizacja z motywem Windows, jeśli włączona
      if Config['auto_sync_windows']
        Config['dark_mode_enabled'] = Config.windows_dark_mode?
      end

      setup_ui
      setup_observers

      UI.start_timer(0.3, false) do
        update_state
      end
    end

    def dark_mode_active?
      Config['dark_mode_enabled'] == true
    end

    def toggle
      if dark_mode_active?
        disable_dark_mode
      else
        enable_dark_mode
      end
    end

    def enable_dark_mode
      Config['dark_mode_enabled'] = true
      Config['auto_sync_windows'] = false

      # 1. Pasek tytułu Windows (DWM)
      DwmStyler.set_dark_titlebar(true) if Config['style_titlebar']

      # 2. Interfejs Qt 6 (Ciemna paleta + QSS)
      if Config['style_ui']
        apply_current_qss
      else
        QtStyler.clear_stylesheet
      end

      # 3. Widok 3D (Viewport)
      if Config['style_viewport']
        ViewportStyler.apply_dark_viewport(Sketchup.active_model)
      else
        ViewportStyler.restore_viewport(Sketchup.active_model)
      end

      update_ui_elements
      puts '[Dark Mode] Tryb ciemny został WŁĄCZONY.'
    end

    def disable_dark_mode
      Config['dark_mode_enabled'] = false
      Config['auto_sync_windows'] = false

      # 1. Pasek tytułu Windows (DWM)
      DwmStyler.set_dark_titlebar(false)

      # 2. Interfejs Qt 6 (Przywrócenie jasnej palety i czyszczenie QSS)
      QtStyler.clear_stylesheet

      # 3. Widok 3D (Przywrócenie domyślnych kolorów canvas)
      ViewportStyler.restore_viewport(Sketchup.active_model)

      update_ui_elements
      puts '[Dark Mode] Przywrócono domyślny jasny motyw SketchUp.'
    end

    def update_state
      if dark_mode_active?
        enable_dark_mode
      else
        disable_dark_mode
      end
    end

    def reload_stylesheet
      is_en = SettingsDialog.english?
      if File.exist?(QSS_PATH)
        puts "[Dark Mode] Reloading stylesheet from #{QSS_PATH}..."
        if dark_mode_active? && Config['style_ui']
          apply_current_qss
        end
        msg = is_en ? "Dark Mode stylesheet has been reloaded successfully!" : "Styl Dark Mode został pomyślnie przeładowany!"
        UI.messagebox(msg, MB_OK)
      else
        msg = is_en ? "Stylesheet file not found:\n#{QSS_PATH}" : "Nie znaleziono pliku stylu:\n#{QSS_PATH}"
        UI.messagebox(msg, MB_OK)
      end
    end

    def on_model_changed(model)
      if dark_mode_active? && Config['style_viewport']
        ViewportStyler.apply_dark_viewport(model)
      end
    end

    def apply_current_qss
      if File.exist?(QSS_PATH)
        qss_content = File.read(QSS_PATH, encoding: 'UTF-8')
        qss_content += materials_list_qss
        QtStyler.apply_stylesheet(qss_content)
      else
        puts "[Dark Mode] Ostrzeżenie: Plik stylów #{QSS_PATH} nie istnieje."
      end
    end

    def materials_list_qss
      if Config['dark_materials_list']
        <<~QSS

          /* ==========================================================================
             Ciemne tło listy materiałów (Włączone)
             ========================================================================== */
          CMaterialListCtrl,
          CMaterialListCtrl::viewport,
          ContentBrowserListCtrl,
          ContentBrowserListCtrl::viewport,
          CBrowserListCtrl,
          CBrowserListCtrl::viewport,
          MaterialListCtrl,
          MaterialListCtrl::viewport {
              background-color: #202022 !important;
              color: #e0e0e0 !important;
              border: 1px solid #38383b !important;
              outline: none;
              min-width: 0px !important;
          }

          CMaterialListCtrl::item,
          ContentBrowserListCtrl::item,
          CBrowserListCtrl::item,
          MaterialListCtrl::item,
          MaterialListItem {
              background-color: #2a2a2d !important;
              color: #ffffff !important;
              font-weight: 600 !important;
              border: 1px solid #3f3f46 !important;
              border-radius: 4px;
          }

          CMaterialListCtrl::item:hover,
          ContentBrowserListCtrl::item:hover,
          CBrowserListCtrl::item:hover,
          MaterialListCtrl::item:hover {
              background-color: #38383c !important;
              border: 1px solid #007acc !important;
              color: #ffffff !important;
          }

          CMaterialListCtrl::item:selected,
          ContentBrowserListCtrl::item:selected,
          CBrowserListCtrl::item:selected,
          MaterialListCtrl::item:selected {
              background-color: #094771 !important;
              border: 2px solid #007acc !important;
              color: #ffffff !important;
          }
        QSS
      else
        <<~QSS

          /* ==========================================================================
             Jasne tło listy materiałów (Biały canvas dla próbek) z mocnym czarnym tekstem
             ========================================================================== */
          CMaterialListCtrl,
          CMaterialListCtrl::viewport,
          ContentBrowserListCtrl,
          ContentBrowserListCtrl::viewport,
          CBrowserListCtrl,
          CBrowserListCtrl::viewport,
          MaterialListCtrl,
          MaterialListCtrl::viewport {
              background-color: #ffffff !important;
              color: #000000 !important;
              border: 1px solid #38383b !important;
              outline: none;
              min-width: 0px !important;
          }

          CMaterialListCtrl,
          CMaterialListCtrl *,
          ContentBrowserListCtrl,
          ContentBrowserListCtrl *,
          CBrowserListCtrl,
          CBrowserListCtrl *,
          MaterialListCtrl,
          MaterialListCtrl *,
          MaterialListItem,
          MaterialListItem *,
          CMaterialListCtrl QLabel,
          CMaterialListCtrl::item,
          ContentBrowserListCtrl::item,
          CBrowserListCtrl::item,
          MaterialListCtrl::item,
          CMaterialBrowserPage QAbstractItemView,
          CMaterialBrowserPage QAbstractItemView *,
          CMaterialBrowserPage QListView,
          CMaterialBrowserPage QListView * {
              color: #000000 !important;
              font-weight: 900 !important;
              font-size: 11px !important;
          }

          CMaterialListCtrl::item,
          ContentBrowserListCtrl::item,
          CBrowserListCtrl::item,
          MaterialListCtrl::item,
          MaterialListItem {
              background-color: transparent !important;
              border: 1px solid transparent !important;
              border-radius: 4px;
          }

          CMaterialListCtrl::item:hover,
          ContentBrowserListCtrl::item:hover,
          CBrowserListCtrl::item:hover,
          MaterialListCtrl::item:hover {
              background-color: #e5e5e5 !important;
              border: 1px solid #007acc !important;
              color: #000000 !important;
          }

          CMaterialListCtrl::item:selected,
          ContentBrowserListCtrl::item:selected,
          CBrowserListCtrl::item:selected,
          MaterialListCtrl::item:selected {
              background-color: #cce8ff !important;
              border: 2px solid #007acc !important;
              color: #003366 !important;
          }
        QSS
      end
    end

    private

    def update_ui_elements
      return unless @cmd_toggle

      is_dark = dark_mode_active?
      icon_suffix = is_dark ? '_active' : ''

      svg_icon = File.join(ICONS_DIR, "dark_mode#{icon_suffix}.svg")
      png_24   = File.join(ICONS_DIR, "dark_mode#{icon_suffix}_24.png")
      png_32   = File.join(ICONS_DIR, "dark_mode#{icon_suffix}_32.png")

      if File.exist?(svg_icon)
        @cmd_toggle.small_icon = svg_icon
        @cmd_toggle.large_icon = svg_icon
      elsif File.exist?(png_24) && File.exist?(png_32)
        @cmd_toggle.small_icon = png_24
        @cmd_toggle.large_icon = png_32
      end

      is_en = SettingsDialog.english?
      status_msg = if is_en
        is_dark ? 'Dark Mode is ON. Click to disable.' : 'Dark Mode is OFF. Click to enable.'
      else
        is_dark ? 'Tryb ciemny jest WŁĄCZONY. Kliknij, aby wyłączyć.' : 'Tryb ciemny jest WYŁĄCZONY. Kliknij, aby włączyć.'
      end
      @cmd_toggle.tooltip = status_msg
      @cmd_toggle.status_bar_text = status_msg
    end

    def setup_ui
      is_en = SettingsDialog.english?

      # 1. Komenda Toggle
      toggle_name = is_en ? 'Toggle Dark Mode' : 'Przełącz tryb ciemny'
      @cmd_toggle = UI::Command.new(toggle_name) do
        Main.toggle
      end
      @cmd_toggle.menu_text = is_en ? 'Toggle Dark Mode (On / Off)' : 'Przełącz tryb ciemny (Włącz / Wyłącz)'
      @cmd_toggle.tooltip = is_en ? 'Toggle Dark Mode' : 'Przełącz tryb ciemny (Dark Mode)'
      @cmd_toggle.status_bar_text = is_en ? 'Enables or disables Dark Mode' : 'Włącza lub wyłącza tryb ciemny'

      @cmd_toggle.set_validation_proc do
        if defined?(MF_CHECKED) && defined?(MF_UNCHECKED)
          Main.dark_mode_active? ? MF_CHECKED : MF_UNCHECKED
        else
          Main.dark_mode_active? ? 1 : 0
        end
      end

      update_ui_elements

      # 2. Komenda Przywróć domyślne (Jasny motyw)
      restore_name = is_en ? 'Restore Default Theme' : 'Przywróć domyślny wygląd'
      @cmd_restore = UI::Command.new(restore_name) do
        Main.disable_dark_mode
      end
      @cmd_restore.menu_text = is_en ? 'Restore Default Theme (Light Mode)' : 'Przywróć domyślny wygląd (Jasny motyw)'
      @cmd_restore.tooltip = is_en ? 'Disables dark mode and restores standard light theme' : 'Wyłącza tryb ciemny i przywraca standardowy jasny motyw SketchUp'
      @cmd_restore.status_bar_text = is_en ? 'Restores default light theme for UI and 3D viewport' : 'Przywraca domyślny jasny motyw interfejsu i widoku 3D'

      sun_svg = File.join(ICONS_DIR, 'light_mode.svg')
      sun_24  = File.join(ICONS_DIR, 'light_mode_24.png')
      sun_32  = File.join(ICONS_DIR, 'light_mode_32.png')

      if File.exist?(sun_svg)
        @cmd_restore.small_icon = sun_svg
        @cmd_restore.large_icon = sun_svg
      elsif File.exist?(sun_24) && File.exist?(sun_32)
        @cmd_restore.small_icon = sun_24
        @cmd_restore.large_icon = sun_32
      end

      # 3. Komenda Przełącz ciemny widok 3D
      vp_name = is_en ? 'Dark 3D Viewport' : 'Ciemny widok 3D (Viewport)'
      cmd_toggle_viewport = UI::Command.new(vp_name) do
        Config['style_viewport'] = !Config['style_viewport']
        if Config['style_viewport'] && Main.dark_mode_active?
          ViewportStyler.apply_dark_viewport(Sketchup.active_model)
        else
          ViewportStyler.restore_viewport(Sketchup.active_model)
        end
      end
      cmd_toggle_viewport.menu_text = is_en ? 'Dark 3D Viewport (On / Off)' : 'Ciemny widok 3D (Włącz / Wyłącz)'
      cmd_toggle_viewport.tooltip = is_en ? 'Toggle dark 3D viewport style' : 'Przełącza ciemny styl obszaru roboczego 3D'
      cmd_toggle_viewport.set_validation_proc do
        if defined?(MF_CHECKED) && defined?(MF_UNCHECKED)
          Config['style_viewport'] ? MF_CHECKED : MF_UNCHECKED
        else
          Config['style_viewport'] ? 1 : 0
        end
      end

      # 4. Komenda Przełącz ciemną listę materiałów
      mat_name = is_en ? 'Dark Materials List Canvas' : 'Ciemne tło listy materiałów'
      cmd_toggle_materials = UI::Command.new(mat_name) do
        Config['dark_materials_list'] = !Config['dark_materials_list']
        Main.apply_current_qss if Main.dark_mode_active?
      end
      cmd_toggle_materials.menu_text = is_en ? 'Dark Materials List (On / Off)' : 'Ciemna lista materiałów (Włącz / Wyłącz)'
      cmd_toggle_materials.tooltip = is_en ? 'Toggle dark / light materials and swatches canvas' : 'Przełącza ciemne / jasne tło listy materiałów i próbek'
      cmd_toggle_materials.set_validation_proc do
        if defined?(MF_CHECKED) && defined?(MF_UNCHECKED)
          Config['dark_materials_list'] ? MF_CHECKED : MF_UNCHECKED
        else
          Config['dark_materials_list'] ? 1 : 0
        end
      end

      # 5. Komenda Ustawienia
      settings_name = is_en ? 'Dark Mode Settings' : 'Ustawienia trybu ciemnego'
      cmd_settings = UI::Command.new(settings_name) do
        SettingsDialog.show
      end
      cmd_settings.menu_text = is_en ? 'Dark Mode Settings...' : 'Ustawienia trybu ciemnego...'
      cmd_settings.tooltip = is_en ? 'Configure Dark Mode settings' : 'Konfiguracja trybu ciemnego'

      # 6. Komenda Przeładuj styl (Hot-Reload)
      reload_name = is_en ? 'Reload CSS Stylesheet' : 'Przeładuj styl CSS'
      cmd_reload = UI::Command.new(reload_name) do
        Main.reload_stylesheet
      end
      cmd_reload.menu_text = is_en ? 'Reload CSS Stylesheet (Hot-Reload)' : 'Przeładuj styl CSS (Hot-Reload)'
      cmd_reload.tooltip = is_en ? 'Refreshes Qt stylesheet from dark_theme.qss' : 'Odświeża arkusz stylów Qt z pliku dark_theme.qss'

      # Menu w Extensions / Rozszerzenia
      menu_title = is_en ? 'Dark Mode' : 'Tryb ciemny (Dark Mode)'
      menu = UI.menu('Plugins').add_submenu(menu_title)
      menu.add_item(@cmd_toggle)
      menu.add_item(@cmd_restore)
      menu.add_separator
      menu.add_item(cmd_toggle_viewport)
      menu.add_item(cmd_toggle_materials)
      menu.add_separator
      menu.add_item(cmd_settings)
      menu.add_separator
      menu.add_item(cmd_reload)

      # Pasek narzędzi (Toolbar) - dokładnie dwa przyciski
      toolbar_title = is_en ? 'Dark Mode' : 'Tryb ciemny'
      @toolbar = UI::Toolbar.new(toolbar_title)
      @toolbar.add_item(@cmd_toggle)
      @toolbar.add_item(cmd_settings)
      @toolbar.restore
    end

    def setup_observers
      @app_observer ||= DarkModeAppObserver.new
      Sketchup.add_observer(@app_observer)
    end
  end
end
