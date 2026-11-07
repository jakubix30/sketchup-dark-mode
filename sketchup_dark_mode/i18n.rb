# frozen_string_literal: true

module SketchupDarkMode
  module I18n
    extend self

    DICTIONARY = {
      en: {
        # Extension & General
        ext_title: 'SketchUp Dark Mode',
        ext_desc: 'Modern Dark Mode for SketchUp 2025 – styles Qt 6 UI, Windows titlebar, and 3D viewport.',
        toolbar_title: 'Dark Mode',
        menu_title: 'Dark Mode',

        # Commands
        cmd_toggle: 'Toggle Dark Mode',
        cmd_toggle_menu: 'Toggle Dark Mode (On / Off)',
        cmd_toggle_tip: 'Toggle Dark Mode',
        cmd_toggle_status: 'Enables or disables Dark Mode',
        status_on: 'Dark Mode is ON. Click to disable.',
        status_off: 'Dark Mode is OFF. Click to enable.',

        cmd_restore: 'Restore Default Theme',
        cmd_restore_menu: 'Restore Default Theme (Light Mode)',
        cmd_restore_tip: 'Disables dark mode and restores standard light theme',
        cmd_restore_status: 'Restores default light theme for UI and 3D viewport',

        cmd_viewport: 'Dark 3D Viewport',
        cmd_viewport_menu: 'Dark 3D Viewport (On / Off)',
        cmd_viewport_tip: 'Toggle dark 3D viewport style',
        cmd_viewport_status: 'Toggles dark background and edge styling for 3D workspace',

        cmd_materials: 'Dark Materials List Canvas',
        cmd_materials_menu: 'Dark Materials List (On / Off)',
        cmd_materials_tip: 'Toggle dark / light materials and swatches canvas',
        cmd_materials_status: 'Toggles dark / light canvas for materials browser',

        cmd_settings: 'Dark Mode Settings',
        cmd_settings_menu: 'Dark Mode Settings...',
        cmd_settings_tip: 'Configure Dark Mode settings',

        cmd_reload: 'Reload CSS Stylesheet',
        cmd_reload_menu: 'Reload CSS Stylesheet (Hot-Reload)',
        cmd_reload_tip: 'Refreshes Qt stylesheet from dark_theme.qss',

        cmd_log: 'View Diagnostic Log File',
        cmd_log_menu: 'View Diagnostic Log File (sketchup_dark_mode.log)',
        cmd_log_tip: 'Opens diagnostic execution log file',

        cmd_pick_color: '3D Viewport Color Picker',
        cmd_pick_color_menu: 'Choose Viewport Colors (Windows Palette)...',
        cmd_pick_color_tip: 'Open native Windows color picker for 3D viewport colors',

        cmd_reset_colors: 'Reset Viewport Colors to Default',
        cmd_reset_colors_menu: 'Reset Viewport Colors to Default',
        cmd_reset_colors_tip: 'Restores standard Dark Mode viewport colors',

        # Settings Dialog
        dialog_title: 'SketchUp Dark Mode Settings',
        opt_dark_mode: 'Dark Mode (Enabled):',
        opt_style_ui: 'Style UI (Qt 6 Palette):',
        opt_apply_qss: 'Apply Qt Stylesheet (QSS Panels):',
        opt_style_titlebar: 'Dark Windows Titlebar:',
        opt_style_viewport: 'Dark 3D Viewport:',
        opt_dark_materials: 'Dark Materials List Canvas:',
        opt_style_tooltips: 'Dark Tooltips (Experimental, recommended restart):',
        opt_auto_sync: 'Sync with Windows Theme:',
        opt_language: 'Language / Język:',
        opt_viewport_bg: '3D Viewport Background (HEX):',
        opt_viewport_edge: '3D Model Edges (HEX):',
        opt_viewport_guide: '3D Guide Lines (HEX):',
        opt_viewport_section: '3D Section Cuts (HEX):',
        opt_viewport_ground: '3D Ground Color (HEX):',
        opt_viewport_sky: '3D Sky Color (HEX):',
        opt_open_picker: 'Open Color Picker (Windows Palette):',
        picker_none: '[Do not open]',
        picker_target_bg: '1. Viewport Background',
        picker_target_edge: '2. Model Edges',
        picker_target_guide: '3. Guide Lines',
        picker_target_section: '4. Section Cuts',
        picker_target_ground: '5. Ground Color',
        picker_target_sky: '6. Sky Color',
        color_picker_dialog_title: 'Choose 3D Viewport Element Color',
        color_picker_prompt: 'Select element to customize with Windows color palette:',
        reset_colors_confirm: 'Do you want to reset all 3D viewport colors to their default dark scheme?',
        reset_colors_done: '3D viewport colors have been reset to defaults.',
        yes: 'Yes',
        no: 'No',

        # Dialog messages
        reload_success: 'Dark Mode stylesheet has been reloaded successfully!',
        reload_error: "Stylesheet file not found:\n%{path}",
        lang_restart_note: 'Language setting saved. Note: To update top-level menu names, please restart SketchUp or reload the extension.'
      },
      pl: {
        # Extension & General
        ext_title: 'SketchUp Dark Mode',
        ext_desc: 'Nowoczesny tryb ciemny (Dark Mode) dla SketchUp 2025 – stylizuje interfejs Qt 6, pasek tytułu Windows oraz obszar roboczy 3D.',
        toolbar_title: 'Tryb ciemny',
        menu_title: 'Tryb ciemny (Dark Mode)',

        # Commands
        cmd_toggle: 'Przełącz tryb ciemny',
        cmd_toggle_menu: 'Przełącz tryb ciemny (Włącz / Wyłącz)',
        cmd_toggle_tip: 'Przełącz tryb ciemny (Dark Mode)',
        cmd_toggle_status: 'Włącza lub wyłącza tryb ciemny',
        status_on: 'Tryb ciemny jest WŁĄCZONY. Kliknij, aby wyłączyć.',
        status_off: 'Tryb ciemny jest WYŁĄCZONY. Kliknij, aby włączyć.',

        cmd_restore: 'Przywróć domyślny wygląd',
        cmd_restore_menu: 'Przywróć domyślny wygląd (Jasny motyw)',
        cmd_restore_tip: 'Wyłącza tryb ciemny i przywraca standardowy jasny motyw SketchUp',
        cmd_restore_status: 'Przywraca domyślny jasny motyw interfejsu i widoku 3D',

        cmd_viewport: 'Ciemny widok 3D (Viewport)',
        cmd_viewport_menu: 'Ciemny widok 3D (Włącz / Wyłącz)',
        cmd_viewport_tip: 'Przełącza ciemny styl obszaru roboczego 3D',
        cmd_viewport_status: 'Przełącza ciemne tło oraz krawędzie widoku 3D',

        cmd_materials: 'Ciemne tło listy materiałów',
        cmd_materials_menu: 'Ciemna lista materiałów (Włącz / Wyłącz)',
        cmd_materials_tip: 'Przełącza ciemne / jasne tło listy materiałów i próbek',
        cmd_materials_status: 'Przełącza ciemne lub jasne tło próbek w zasobniku materiałów',

        cmd_settings: 'Ustawienia trybu ciemnego',
        cmd_settings_menu: 'Ustawienia trybu ciemnego...',
        cmd_settings_tip: 'Konfiguracja trybu ciemnego',

        cmd_reload: 'Przeładuj styl CSS',
        cmd_reload_menu: 'Przeładuj styl CSS (Hot-Reload)',
        cmd_reload_tip: 'Odświeża arkusz stylów Qt z pliku dark_theme.qss',

        cmd_log: 'Pokaż plik dziennika (Log)',
        cmd_log_menu: 'Pokaż plik dziennika (sketchup_dark_mode.log)',
        cmd_log_tip: 'Otwiera plik diagnostyczny dziennika zdarzeń',

        cmd_pick_color: 'Selektor kolorów widoku 3D',
        cmd_pick_color_menu: 'Wybierz kolory z palety Windows...',
        cmd_pick_color_tip: 'Otwórz systemową paletę kolorów Windows dla elementów widoku 3D',

        cmd_reset_colors: 'Przywróć domyślne kolory widoku 3D',
        cmd_reset_colors_menu: 'Przywróć domyślne kolory widoku 3D',
        cmd_reset_colors_tip: 'Przywraca standardowe ciemne kolory widoku 3D',

        # Settings Dialog
        dialog_title: 'Ustawienia SketchUp Dark Mode',
        opt_dark_mode: 'Tryb ciemny (Włączony):',
        opt_style_ui: 'Stylizuj interfejs (Paleta Qt 6):',
        opt_apply_qss: 'Arkusz stylów Qt (QSS Panele):',
        opt_style_titlebar: 'Ciemny pasek tytułu Windows:',
        opt_style_viewport: 'Ciemny obszar roboczy 3D (Viewport):',
        opt_dark_materials: 'Ciemne tło listy materiałów:',
        opt_style_tooltips: 'Ciemne dymki podpowiedzi (Eksperymentalne, zalecany restart):',
        opt_auto_sync: 'Synchronizuj z motywem Windows:',
        opt_language: 'Język / Language:',
        opt_viewport_bg: 'Kolor tła widoku 3D (HEX):',
        opt_viewport_edge: 'Kolor krawędzi modeli 3D (HEX):',
        opt_viewport_guide: 'Kolor linii pomocniczych / prowadnic (HEX):',
        opt_viewport_section: 'Kolor płaszczyzn i linii przekrojów (HEX):',
        opt_viewport_ground: 'Kolor podłoża / ziemi (HEX):',
        opt_viewport_sky: 'Kolor nieba (HEX):',
        opt_open_picker: 'Otwórz selektor koloru Windows (Paleta):',
        picker_none: '[Nie otwieraj]',
        picker_target_bg: '1. Tło widoku 3D',
        picker_target_edge: '2. Krawędzie modeli',
        picker_target_guide: '3. Linie pomocnicze',
        picker_target_section: '4. Przekroje',
        picker_target_ground: '5. Podłoże',
        picker_target_sky: '6. Niebo',
        color_picker_dialog_title: 'Wybierz element do zmiany koloru',
        color_picker_prompt: 'Wybierz element, dla którego chcesz otworzyć paletę Windows:',
        reset_colors_confirm: 'Czy na pewno chcesz przywrócić domyślne ciemne kolory obszaru roboczego 3D?',
        reset_colors_done: 'Przywrócono domyślne ciemne kolory widoku 3D.',
        yes: 'Tak',
        no: 'Nie',

        # Dialog messages
        reload_success: 'Styl Dark Mode został pomyślnie przeładowany!',
        reload_error: "Nie znaleziono pliku stylu:\n%{path}",
        lang_restart_note: 'Zapisano ustawienia języka. Uwaga: Aby zaktualizować główne menu rozszerzeń, uruchom ponownie SketchUp lub przeładuj wtyczkę.'
      }
    }.freeze

    def locale
      lang = Config['language'].to_s.downcase
      return :en if lang == 'en' || lang == 'english'
      return :pl if lang == 'pl' || lang == 'polish'

      # Auto detect based on Sketchup locale
      loc = (Sketchup.respond_to?(:get_locale) ? Sketchup.get_locale.to_s.downcase : 'en')
      loc.start_with?('pl') ? :pl : :en
    end

    def english?
      locale == :en
    end

    def polish?
      locale == :pl
    end

    def t(key, vars = {})
      loc = locale
      str = DICTIONARY.dig(loc, key.to_sym) || DICTIONARY.dig(:en, key.to_sym) || key.to_s
      vars.each { |k, v| str = str.gsub("%{#{k}}", v.to_s) }
      str
    end
  end
end
