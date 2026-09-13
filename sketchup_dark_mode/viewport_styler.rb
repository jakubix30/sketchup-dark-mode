# frozen_string_literal: true

module SketchupDarkMode
  module ViewportStyler
    extend self

    @saved_styles = {} # model_id => hash of saved settings

    # Konwertuje hex string np. "#1e1e20" na Sketchup::Color
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
        'ForegroundColor'        => hex_to_color(edge_hex), # Kolor krawędzi w trybie 0
        'DrawGround'             => false,
        'GroundColor'            => hex_to_color('#242426'),
        'DrawHorizon'            => false,
        'SkyColor'               => hex_to_color('#1a1a1c'),
        'EdgeColorMode'          => 0, # Wszystkie krawędzie w jednym kolorze (ForegroundColor)
        'ConstructionColor'      => hex_to_color('#50a0f0'), # Linie pomocnicze
        'SectionDefaultCutColor' => hex_to_color('#e04545'), # Przekroje
        'ModelViewColor'         => hex_to_color('#2a2a2d')
      }
    end

    # Nakłada ciemny styl na widok 3D wskazanego modelu
    def apply_dark_viewport(model = Sketchup.active_model)
      return unless model && model.valid?

      ro = model.rendering_options
      key = model.object_id

      # Zachowaj oryginalne ustawienia tylko jeśli jeszcze nie są zapisane dla tego modelu
      unless @saved_styles.key?(key)
        opts = dark_viewport_options
        backup = {}
        opts.each_key do |k|
          backup[k] = ro[k] if ro.keys.include?(k)
        end
        @saved_styles[key] = backup
      end

      # Zastosuj ciemny schemat
      dark_viewport_options.each do |k, v|
        ro[k] = v if ro.keys.include?(k)
      end

      model.active_view.invalidate if model.active_view
      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd stylizowania viewportu: #{e.message}"
      false
    end

    # Przywraca oryginalny styl widoku 3D
    def restore_viewport(model = Sketchup.active_model)
      return unless model && model.valid?

      key = model.object_id
      ro = model.rendering_options
      if @saved_styles.key?(key)
        @saved_styles[key].each do |k, v|
          ro[k] = v if ro.keys.include?(k)
        end
        @saved_styles.delete(key)
      else
        # Domyślne wartości SketchUp jeśli brak zapisanego stanu
        ro['BackgroundColor']   = Sketchup::Color.new(255, 255, 255)
        ro['ForegroundColor']   = Sketchup::Color.new(0, 0, 0)
        ro['DrawGround']        = true
        ro['GroundColor']       = Sketchup::Color.new(208, 204, 180)
        ro['DrawHorizon']       = true
        ro['SkyColor']          = Sketchup::Color.new(198, 218, 238)
        ro['EdgeColorMode']     = 0
        ro['ConstructionColor'] = Sketchup::Color.new(0, 0, 0)
      end

      model.active_view.invalidate if model.active_view
      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd przywracania widoku: #{e.message}"
      false
    end

    def remove_saved(model)
      @saved_styles.delete(model.object_id) if model
    end
  end
end
