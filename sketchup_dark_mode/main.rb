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

      # Zastosuj początkowy stan po załadowaniu interfejsu SketchUp
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

      # 1. Pasek tytułu Windows (DWM)
      DwmStyler.set_dark_titlebar(true) if Config['style_titlebar']

      # 2. Interfejs Qt 6 (QSS)
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
    end

    def disable_dark_mode
      Config['dark_mode_enabled'] = false

      # 1. Pasek tytułu Windows (DWM)
      DwmStyler.set_dark_titlebar(false)

      # 2. Interfejs Qt 6
      QtStyler.clear_stylesheet

      # 3. Widok 3D
      ViewportStyler.restore_viewport(Sketchup.active_model)

      update_ui_elements
    end

    def update_state
      if dark_mode_active?
        enable_dark_mode
      else
        disable_dark_mode
      end
    end

    def reload_stylesheet
      if File.exist?(QSS_PATH)
        puts "[Dark Mode] Przeładowywanie stylu CSS z #{QSS_PATH}..."
        if dark_mode_active? && Config['style_ui']
          apply_current_qss
        end
        UI.messagebox("Styl Dark Mode został pomyślnie przeładowany!", MB_OK)
      else
        UI.messagebox("Nie znaleziono pliku stylu:\n#{QSS_PATH}", MB_OK)
      end
    end

    def on_model_changed(model)
      if dark_mode_active? && Config['style_viewport']
        ViewportStyler.apply_dark_viewport(model)
      end
    end

    private

    def apply_current_qss
      if File.exist?(QSS_PATH)
        qss_content = File.read(QSS_PATH, encoding: 'UTF-8')
        QtStyler.apply_stylesheet(qss_content)
      else
        puts "[Dark Mode] Ostrzeżenie: Plik stylów #{QSS_PATH} nie istnieje."
      end
    end

    def update_ui_elements
      return unless @cmd_toggle

      is_dark = dark_mode_active?
      icon_suffix = is_dark ? '_active' : ''

      # Ikony dla SketchUp 2025 (SVG lub PNG)
      svg_icon = File.join(ICONS_DIR, "dark_mode#{icon_suffix}.svg")
      png_24 = File.join(ICONS_DIR, "dark_mode#{icon_suffix}_24.png")
      png_32 = File.join(ICONS_DIR, "dark_mode#{icon_suffix}_32.png")

      if File.exist?(svg_icon)
        @cmd_toggle.small_icon = svg_icon
        @cmd_toggle.large_icon = svg_icon
      elsif File.exist?(png_24) && File.exist?(png_32)
        @cmd_toggle.small_icon = png_24
        @cmd_toggle.large_icon = png_32
      end

      status_msg = is_dark ? 'Tryb ciemny jest WŁĄCZONY. Kliknij, aby wyłączyć.' : 'Tryb ciemny jest WYŁĄCZONY. Kliknij, aby włączyć.'
      @cmd_toggle.tooltip = status_msg
      @cmd_toggle.status_bar_text = status_msg
    end

    def setup_ui
      # Tworzenie komendy Toggle
      @cmd_toggle = UI::Command.new('Przełącz tryb ciemny') do
        Main.toggle
      end

      @cmd_toggle.menu_text = 'Przełącz tryb ciemny'
      @cmd_toggle.tooltip = 'Przełącz tryb ciemny (Dark Mode)'
      @cmd_toggle.status_bar_text = 'Włącza lub wyłącza tryb ciemny interfejsu i widoku 3D'

      update_ui_elements

      # Komenda Ustawienia
      cmd_settings = UI::Command.new('Ustawienia trybu ciemnego') do
        SettingsDialog.show
      end
      cmd_settings.menu_text = 'Ustawienia trybu ciemnego...'
      cmd_settings.tooltip = 'Konfiguracja trybu ciemnego'

      # Komenda Przeładuj styl (Hot-Reload)
      cmd_reload = UI::Command.new('Przeładuj styl CSS') do
        Main.reload_stylesheet
      end
      cmd_reload.menu_text = 'Przeładuj styl CSS (Hot-Reload)'
      cmd_reload.tooltip = 'Odświeża arkusz stylów Qt z pliku dark_theme.qss'

      # Menu w Extensions / Rozszerzenia
      menu = UI.menu('Plugins').add_submenu('Tryb ciemny (Dark Mode)')
      menu.add_item(@cmd_toggle)
      menu.add_item(cmd_settings)
      menu.add_separator
      menu.add_item(cmd_reload)

      # Pasek narzędzi (Toolbar)
      @toolbar = UI::Toolbar.new('Tryb ciemny')
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
