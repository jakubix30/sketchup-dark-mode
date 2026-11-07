# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module ColorPicker
    extend self

    CC_RGBINIT   = 0x00000001
    CC_FULLOPEN  = 0x00000002
    CC_ANYCOLOR  = 0x00000100

    @cust_colors_ptr = nil

    # Converts hex '#rrggbb' to Windows COLORREF (0x00BBGGRR)
    def hex_to_colorref(hex)
      hex = hex.to_s.sub(/^#/, '').strip
      return 0x00201E1E if hex.length < 6

      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
      (b << 16) | (g << 8) | r
    rescue StandardError
      0x00201E1E
    end

    # Converts Windows COLORREF (0x00BBGGRR) to hex '#rrggbb'
    def colorref_to_hex(colorref)
      r = colorref & 0xFF
      g = (colorref >> 8) & 0xFF
      b = (colorref >> 16) & 0xFF
      format('#%02x%02x%02x', r, g, b)
    end

    # Pointer to 16 COLORREFs (64 bytes) for custom colors palette in ChooseColor
    def custom_colors_pointer
      return @cust_colors_ptr if @cust_colors_ptr

      @cust_colors_ptr = Fiddle::Pointer.malloc(64)
      # Load saved custom colors from Config if present
      saved = (Config['custom_colors'] rescue nil) || []
      16.times do |i|
        ref = saved[i] ? hex_to_colorref(saved[i]) : 0x00FFFFFF
        @cust_colors_ptr[i * 4, 4] = [ref].pack('L<')
      end
      @cust_colors_ptr
    end

    # Saves current custom colors from pointer back to Config
    def save_custom_colors
      return unless @cust_colors_ptr

      colors = 16.times.map do |i|
        ref = @cust_colors_ptr[i * 4, 4].unpack1('L<')
        colorref_to_hex(ref)
      end
      Config['custom_colors'] = colors if defined?(Config)
    rescue StandardError => e
      Logger.error('[ColorPicker] Error saving custom colors', e) if defined?(Logger)
    end

    # Opens native Windows ChooseColor dialog.
    # Returns hex string '#rrggbb' if OK was clicked, or nil if canceled.
    def choose_color(initial_hex = '#1e1e20', parent_hwnd = nil)
      comdlg32 = Fiddle.dlopen('comdlg32.dll')
      fn_choose_color = Fiddle::Function.new(
        comdlg32['ChooseColorW'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_INT
      )

      hwnd = parent_hwnd
      if hwnd.nil? || hwnd.to_i == 0
        hwnd = (Sketchup.respond_to?(:get_main_window) ? Sketchup.get_main_window : 0)
      end

      initial_ref = hex_to_colorref(initial_hex)
      flags = CC_RGBINIT | CC_FULLOPEN | CC_ANYCOLOR
      cust_ptr = custom_colors_pointer

      # 72 bytes CHOOSECOLORW struct on 64-bit Windows:
      # 0x00 (4): lStructSize (72)
      # 0x04 (4): padding
      # 0x08 (8): hwndOwner
      # 0x10 (8): hInstance
      # 0x18 (4): rgbResult
      # 0x1C (4): padding
      # 0x20 (8): lpCustColors
      # 0x28 (4): Flags
      # 0x2C (4): padding
      # 0x30 (8): lCustData
      # 0x38 (8): lpfnHook
      # 0x40 (8): lpTemplateName
      cc_struct = [
        72, 0,
        hwnd.to_i,
        0,
        initial_ref, 0,
        cust_ptr.to_i,
        flags, 0,
        0,
        0,
        0
      ].pack('L<L<Q<Q<L<L<Q<L<L<Q<Q<Q<')

      buf_ptr = Fiddle::Pointer[cc_struct]
      ret = fn_choose_color.call(buf_ptr)

      if ret != 0
        res_ref = buf_ptr[24, 4].unpack1('L<')
        chosen_hex = colorref_to_hex(res_ref)
        save_custom_colors
        Logger.info("[ColorPicker] User picked color: #{chosen_hex}") if defined?(Logger)
        chosen_hex
      else
        Logger.info('[ColorPicker] Color picker canceled by user') if defined?(Logger)
        nil
      end
    rescue StandardError => e
      Logger.error('[ColorPicker] Error displaying ChooseColor dialog', e) if defined?(Logger)
      nil
    end
  end
end
