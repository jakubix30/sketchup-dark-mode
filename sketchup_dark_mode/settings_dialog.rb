# frozen_string_literal: true

module SketchupDarkMode
  module SettingsDialog
    extend self

    def english?
      lang = Config['language'].to_s.downcase
      return true if lang == 'en' || lang == 'english'
      return false if lang == 'pl' || lang == 'polish'

      locale = (Sketchup.respond_to?(:get_locale) ? Sketchup.get_locale.to_s.downcase : 'en')
      !locale.start_with?('pl')
    end

    def show
      is_en = english?

      yes_text = is_en ? 'Yes' : 'Tak'
      no_text  = is_en ? 'No' : 'Nie'

      prompts = if is_en
        [
          'Dark Mode (Enabled):',
          'Style UI (Qt 6):',
          'Dark Windows Titlebar:',
          'Dark 3D Viewport:',
          'Dark Materials List Canvas:',
          'Sync with Windows Theme:',
          'Language / Język:',
          '3D Viewport Background (HEX):',
          '3D Model Edges (HEX):'
        ]
      else
        [
          'Tryb ciemny (Włączony):',
          'Stylizuj interfejs (Qt 6):',
          'Ciemny pasek tytułu Windows:',
          'Ciemny obszar roboczy 3D (Viewport):',
          'Ciemne tło listy materiałów:',
          'Synchronizuj z motywem Windows:',
          'Język / Language:',
          'Kolor tła widoku 3D (HEX):',
          'Kolor krawędzi modeli 3D (HEX):'
        ]
      end

      current_lang = case Config['language'].to_s.downcase
                     when 'en', 'english' then 'English'
                     when 'pl', 'polish'  then 'Polski'
                     else 'Auto'
                     end

      defaults = [
        Config['dark_mode_enabled'] ? yes_text : no_text,
        Config['style_ui'] ? yes_text : no_text,
        Config['style_titlebar'] ? yes_text : no_text,
        Config['style_viewport'] ? yes_text : no_text,
        Config['dark_materials_list'] ? yes_text : no_text,
        Config['auto_sync_windows'] ? yes_text : no_text,
        current_lang,
        Config['viewport_bg_hex'] || '#1e1e20',
        Config['viewport_edge_hex'] || '#dedee0'
      ]

      yes_no_list = "#{yes_text}|#{no_text}"
      lists = [
        yes_no_list,
        yes_no_list,
        yes_no_list,
        yes_no_list,
        yes_no_list,
        yes_no_list,
        'Auto|English|Polski',
        '',
        ''
      ]

      dialog_title = is_en ? 'SketchUp Dark Mode Settings' : 'Ustawienia SketchUp Dark Mode'
      results = UI.inputbox(prompts, defaults, lists, dialog_title)
      return unless results

      Config['dark_mode_enabled']   = (results[0] == yes_text)
      Config['style_ui']            = (results[1] == yes_text)
      Config['style_titlebar']      = (results[2] == yes_text)
      Config['style_viewport']      = (results[3] == yes_text)
      Config['dark_materials_list'] = (results[4] == yes_text)
      Config['auto_sync_windows']   = (results[5] == yes_text)

      selected_lang = results[6].to_s.strip
      Config['language'] = case selected_lang
                           when 'English' then 'en'
                           when 'Polski'  then 'pl'
                           else 'auto'
                           end

      Config['viewport_bg_hex']   = results[7].to_s.strip
      Config['viewport_edge_hex'] = results[8].to_s.strip

      # Natychmiast zaktualizuj stan aplikacji
      Main.update_state
    end
  end
end
