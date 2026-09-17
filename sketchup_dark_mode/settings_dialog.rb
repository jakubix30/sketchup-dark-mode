# frozen_string_literal: true

module SketchupDarkMode
  module SettingsDialog
    extend self

    def show
      yes_text = I18n.t(:yes)
      no_text  = I18n.t(:no)

      prompts = [
        I18n.t(:opt_dark_mode),
        I18n.t(:opt_style_ui),
        I18n.t(:opt_apply_qss),
        I18n.t(:opt_style_titlebar),
        I18n.t(:opt_style_viewport),
        I18n.t(:opt_dark_materials),
        I18n.t(:opt_style_tooltips),
        I18n.t(:opt_auto_sync),
        I18n.t(:opt_language),
        I18n.t(:opt_viewport_bg),
        I18n.t(:opt_viewport_edge)
      ]

      current_lang = case Config['language'].to_s.downcase
                     when 'en', 'english' then 'English'
                     when 'pl', 'polish'  then 'Polski'
                     else 'Auto'
                     end

      defaults = [
        Config['dark_mode_enabled'] ? yes_text : no_text,
        Config['style_ui'] ? yes_text : no_text,
        Config['apply_qss'] != false ? yes_text : no_text,
        Config['style_titlebar'] ? yes_text : no_text,
        Config['style_viewport'] ? yes_text : no_text,
        Config['dark_materials_list'] ? yes_text : no_text,
        Config['style_tooltips'] ? yes_text : no_text,
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
        yes_no_list,
        yes_no_list,
        'Auto|English|Polski',
        '',
        ''
      ]

      results = UI.inputbox(prompts, defaults, lists, I18n.t(:dialog_title))
      return unless results

      old_lang = Config['language'].to_s.downcase

      Config['dark_mode_enabled']   = (results[0] == yes_text)
      Config['style_ui']            = (results[1] == yes_text)
      Config['apply_qss']           = (results[2] == yes_text)
      Config['style_titlebar']      = (results[3] == yes_text)
      Config['style_viewport']      = (results[4] == yes_text)
      Config['dark_materials_list'] = (results[5] == yes_text)
      Config['style_tooltips']      = (results[6] == yes_text)
      Config['auto_sync_windows']   = (results[7] == yes_text)

      selected_lang = results[8].to_s.strip
      new_lang = case selected_lang
                 when 'English' then 'en'
                 when 'Polski'  then 'pl'
                 else 'auto'
                 end
      Config['language'] = new_lang

      Config['viewport_bg_hex']   = results[9].to_s.strip
      Config['viewport_edge_hex'] = results[10].to_s.strip

      # Immediately apply state changes
      Main.update_state

      # If language changed, refresh dynamic UI elements
      if old_lang != new_lang
        Main.update_ui_elements
      end
    end
  end
end
