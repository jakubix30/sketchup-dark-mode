# frozen_string_literal: true

module SketchupDarkMode
  module SettingsDialog
    extend self

    def show
      yes_text = I18n.t(:yes)
      no_text  = I18n.t(:no)

      picker_none       = I18n.t(:picker_none)
      picker_target_bg  = I18n.t(:picker_target_bg)
      picker_target_edge = I18n.t(:picker_target_edge)
      picker_target_guide = I18n.t(:picker_target_guide)
      picker_target_section = I18n.t(:picker_target_section)
      picker_target_ground = I18n.t(:picker_target_ground)
      picker_target_sky = I18n.t(:picker_target_sky)

      picker_list = [
        picker_none,
        picker_target_bg,
        picker_target_edge,
        picker_target_guide,
        picker_target_section,
        picker_target_ground,
        picker_target_sky
      ].join('|')

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
        I18n.t(:opt_viewport_edge),
        I18n.t(:opt_viewport_guide),
        I18n.t(:opt_viewport_section),
        I18n.t(:opt_viewport_ground),
        I18n.t(:opt_viewport_sky),
        I18n.t(:opt_open_picker)
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
        Config['viewport_edge_hex'] || '#dedee0',
        Config['viewport_guide_hex'] || '#50a0f0',
        Config['viewport_section_hex'] || '#e04545',
        Config['viewport_ground_hex'] || '#242426',
        Config['viewport_sky_hex'] || '#1a1a1c',
        picker_none
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
        '',
        '',
        '',
        '',
        '',
        picker_list
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

      Config['viewport_bg_hex']      = results[9].to_s.strip
      Config['viewport_edge_hex']    = results[10].to_s.strip
      Config['viewport_guide_hex']   = results[11].to_s.strip
      Config['viewport_section_hex'] = results[12].to_s.strip
      Config['viewport_ground_hex']  = results[13].to_s.strip
      Config['viewport_sky_hex']     = results[14].to_s.strip

      # If user selected an element to customize with the native Windows color picker
      picker_choice = results[15].to_s.strip
      if picker_choice != picker_none && defined?(ColorPicker)
        handle_picker_selection(picker_choice, picker_target_bg, picker_target_edge,
                                picker_target_guide, picker_target_section,
                                picker_target_ground, picker_target_sky)
      end

      # Immediately apply state changes
      Main.update_state

      # If language changed, refresh dynamic UI elements
      if old_lang != new_lang
        Main.update_ui_elements
      end
    end

    def pick_color_interactive
      picker_target_bg      = I18n.t(:picker_target_bg)
      picker_target_edge    = I18n.t(:picker_target_edge)
      picker_target_guide   = I18n.t(:picker_target_guide)
      picker_target_section = I18n.t(:picker_target_section)
      picker_target_ground  = I18n.t(:picker_target_ground)
      picker_target_sky     = I18n.t(:picker_target_sky)

      options = [
        "#{picker_target_bg} (#{Config['viewport_bg_hex'] || '#1e1e20'})",
        "#{picker_target_edge} (#{Config['viewport_edge_hex'] || '#dedee0'})",
        "#{picker_target_guide} (#{Config['viewport_guide_hex'] || '#50a0f0'})",
        "#{picker_target_section} (#{Config['viewport_section_hex'] || '#e04545'})",
        "#{picker_target_ground} (#{Config['viewport_ground_hex'] || '#242426'})",
        "#{picker_target_sky} (#{Config['viewport_sky_hex'] || '#1a1a1c'})"
      ]

      prompts = [I18n.t(:color_picker_prompt)]
      defaults = [options[0]]
      lists = [options.join('|')]

      results = UI.inputbox(prompts, defaults, lists, I18n.t(:color_picker_dialog_title))
      return unless results

      selected = results[0].to_s
      target_key = nil
      current_hex = '#1e1e20'

      if selected.start_with?(picker_target_bg)
        target_key = 'viewport_bg_hex'
        current_hex = Config['viewport_bg_hex'] || '#1e1e20'
      elsif selected.start_with?(picker_target_edge)
        target_key = 'viewport_edge_hex'
        current_hex = Config['viewport_edge_hex'] || '#dedee0'
      elsif selected.start_with?(picker_target_guide)
        target_key = 'viewport_guide_hex'
        current_hex = Config['viewport_guide_hex'] || '#50a0f0'
      elsif selected.start_with?(picker_target_section)
        target_key = 'viewport_section_hex'
        current_hex = Config['viewport_section_hex'] || '#e04545'
      elsif selected.start_with?(picker_target_ground)
        target_key = 'viewport_ground_hex'
        current_hex = Config['viewport_ground_hex'] || '#242426'
      elsif selected.start_with?(picker_target_sky)
        target_key = 'viewport_sky_hex'
        current_hex = Config['viewport_sky_hex'] || '#1a1a1c'
      end

      return unless target_key && defined?(ColorPicker)

      new_hex = ColorPicker.choose_color(current_hex)
      if new_hex
        Config[target_key] = new_hex
        Main.update_state
      end
    end

    def reset_colors
      choice = UI.messagebox(I18n.t(:reset_colors_confirm), MB_YESNO)
      return unless choice == IDYES || choice == 6

      Config['viewport_bg_hex']      = '#1e1e20'
      Config['viewport_edge_hex']    = '#dedee0'
      Config['viewport_guide_hex']   = '#50a0f0'
      Config['viewport_section_hex'] = '#e04545'
      Config['viewport_ground_hex']  = '#242426'
      Config['viewport_sky_hex']     = '#1a1a1c'

      Main.update_state
      UI.messagebox(I18n.t(:reset_colors_done), MB_OK)
    end

    private

    def handle_picker_selection(choice, target_bg, target_edge, target_guide, target_section, target_ground, target_sky)
      case choice
      when target_bg
        hex = ColorPicker.choose_color(Config['viewport_bg_hex'] || '#1e1e20')
        Config['viewport_bg_hex'] = hex if hex
      when target_edge
        hex = ColorPicker.choose_color(Config['viewport_edge_hex'] || '#dedee0')
        Config['viewport_edge_hex'] = hex if hex
      when target_guide
        hex = ColorPicker.choose_color(Config['viewport_guide_hex'] || '#50a0f0')
        Config['viewport_guide_hex'] = hex if hex
      when target_section
        hex = ColorPicker.choose_color(Config['viewport_section_hex'] || '#e04545')
        Config['viewport_section_hex'] = hex if hex
      when target_ground
        hex = ColorPicker.choose_color(Config['viewport_ground_hex'] || '#242426')
        Config['viewport_ground_hex'] = hex if hex
      when target_sky
        hex = ColorPicker.choose_color(Config['viewport_sky_hex'] || '#1a1a1c')
        Config['viewport_sky_hex'] = hex if hex
      end
    end
  end
end
