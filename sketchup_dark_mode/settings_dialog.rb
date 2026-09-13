# frozen_string_literal: true

module SketchupDarkMode
  module SettingsDialog
    extend self

    def show
      prompts = [
        'Tryb ciemny (Włączony):',
        'Stylizuj interfejs (Qt 6):',
        'Ciemny pasek tytułu Windows:',
        'Ciemny obszar roboczy 3D (Viewport):',
        'Ciemne tło listy materiałów:',
        'Synchronizuj z motywem Windows:',
        'Kolor tła widoku 3D (HEX):',
        'Kolor krawędzi modeli 3D (HEX):'
      ]

      defaults = [
        Config['dark_mode_enabled'] ? 'Tak' : 'Nie',
        Config['style_ui'] ? 'Tak' : 'Nie',
        Config['style_titlebar'] ? 'Tak' : 'Nie',
        Config['style_viewport'] ? 'Tak' : 'Nie',
        Config['dark_materials_list'] ? 'Tak' : 'Nie',
        Config['auto_sync_windows'] ? 'Tak' : 'Nie',
        Config['viewport_bg_hex'] || '#1e1e20',
        Config['viewport_edge_hex'] || '#dedee0'
      ]

      lists = [
        'Tak|Nie',
        'Tak|Nie',
        'Tak|Nie',
        'Tak|Nie',
        'Tak|Nie',
        'Tak|Nie',
        '',
        ''
      ]

      results = UI.inputbox(prompts, defaults, lists, 'Ustawienia SketchUp Dark Mode')
      return unless results

      Config['dark_mode_enabled']   = (results[0] == 'Tak')
      Config['style_ui']            = (results[1] == 'Tak')
      Config['style_titlebar']      = (results[2] == 'Tak')
      Config['style_viewport']      = (results[3] == 'Tak')
      Config['dark_materials_list'] = (results[4] == 'Tak')
      Config['auto_sync_windows']   = (results[5] == 'Tak')
      Config['viewport_bg_hex']     = results[6].to_s.strip
      Config['viewport_edge_hex']   = results[7].to_s.strip

      # Natychmiast zaktualizuj stan aplikacji
      Main.update_state
    end
  end
end
