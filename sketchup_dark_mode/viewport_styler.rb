# frozen_string_literal: true

module SketchupDarkMode
  module ViewportStyler
    extend self

    @saved_styles = {} # model_id => hash of saved settings

    # Converts hex string e.g. "#1e1e20" to Sketchup::Color
    def hex_to_color(hex)
      hex = hex.to_s.sub('#', '')
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
      Sketchup::Color.new(r, g, b)
    rescue StandardError
      Sketchup::Color.new(30, 30, 32)
    end

    def dark_viewport_options
      bg_hex = Config['viewport_bg_hex'] || '#1e1e20'
      edge_hex = Config['viewport_edge_hex'] || '#dedee0'

      {
        'BackgroundColor'        => hex_to_color(bg_hex),
        'ForegroundColor'        => hex_to_color(edge_hex), # Edge color in mode 0
        'DrawGround'             => false,
        'GroundColor'            => hex_to_color('#242426'),
        'DrawHorizon'            => false,
        'SkyColor'               => hex_to_color('#1a1a1c'),
        'EdgeColorMode'          => 0, # All edges in single color (ForegroundColor)
        'ConstructionColor'      => hex_to_color('#50a0f0'), # Guide lines
        'SectionDefaultCutColor' => hex_to_color('#e04545'), # Section cuts
        'ModelViewColor'         => hex_to_color('#2a2a2d')
      }
    end

    # Applies dark style to the 3D viewport of the specified model
    def apply_dark_viewport(model = Sketchup.active_model)
      return unless model && model.valid?
      return unless Config['style_viewport']

      ro = model.rendering_options
      key = model.object_id

      # Preserve original settings only if not already saved for this model
      unless @saved_styles.key?(key)
        opts = dark_viewport_options
        backup = {}
        opts.each_key do |k|
          backup[k] = ro[k] if ro.keys.include?(k)
        end
        @saved_styles[key] = backup
      end

      # Apply dark scheme
      dark_viewport_options.each do |k, v|
        ro[k] = v if ro.keys.include?(k)
      end

      model.active_view.invalidate if model.active_view
      true
    rescue StandardError => e
      puts "[Dark Mode] Error styling viewport: #{e.message}"
      false
    end

    # Restores original 3D viewport style
    def restore_viewport(model = Sketchup.active_model)
      return unless model && model.valid?

      key = model.object_id
      ro = model.rendering_options

      # 1. Restore from session memory if backup exists
      if @saved_styles.key?(key)
        @saved_styles[key].each do |k, v|
          ro[k] = v if ro.keys.include?(k)
        end
        @saved_styles.delete(key)
      else
        # Default SketchUp values if no saved state exists
        ro['BackgroundColor']   = Sketchup::Color.new(255, 255, 255)
        ro['ForegroundColor']   = Sketchup::Color.new(0, 0, 0)
        ro['DrawGround']        = true
        ro['GroundColor']       = Sketchup::Color.new(208, 204, 180)
        ro['DrawHorizon']       = true
        ro['SkyColor']          = Sketchup::Color.new(198, 218, 238)
        ro['EdgeColorMode']     = 0
        ro['ConstructionColor'] = Sketchup::Color.new(0, 0, 0)
      end

      # 2. Reload active style from model (restores 100% of native user template parameters)
      if model.styles && model.styles.selected_style
        model.styles.selected_style = model.styles.selected_style
      end

      model.active_view.invalidate if model.active_view
      true
    rescue StandardError => e
      puts "[Dark Mode] Error restoring viewport: #{e.message}"
      false
    end

    def remove_saved(model)
      @saved_styles.delete(model.object_id) if model
    end
  end
end
