# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module DwmStyler
    extend self

    DWMWA_USE_IMMERSIVE_DARK_MODE = 20
    DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19
    SWP_FRAMECHANGED = 0x0020
    SWP_NOMOVE = 0x0002
    SWP_NOSIZE = 0x0001
    SWP_NOZORDER = 0x0004
    SWP_FLAGS = SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER

    # Włącza lub wyłącza ciemny pasek tytułu Windows (Immersive Dark Mode)
    def set_dark_titlebar(enable = true)
      hwnd = Sketchup.get_main_window
      if hwnd.nil? || hwnd == 0
        puts '[Dark Mode] Nie udało się pobrać uchwytu głównego okna SketchUp.'
        return false
      end

      dwmapi = Fiddle.dlopen('dwmapi.dll')
      user32 = Fiddle.dlopen('user32.dll')

      dwm_set_window_attribute = Fiddle::Function.new(
        dwmapi['DwmSetWindowAttribute'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
        Fiddle::TYPE_INT
      )

      set_window_pos = Fiddle::Function.new(
        user32['SetWindowPos'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT],
        Fiddle::TYPE_INT
      )

      val = enable ? 1 : 0
      pv_attribute = [val].pack('L')

      # Próba atrybutu 20 (Windows 11 / nowsze Win 10)
      hr = dwm_set_window_attribute.call(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, pv_attribute, 4)
      if hr != 0
        # W razie starszej kompilacji Win 10 próba atrybutu 19
        dwm_set_window_attribute.call(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, pv_attribute, 4)
      end

      # Odświeżenie ramki okna
      set_window_pos.call(hwnd, 0, 0, 0, 0, 0, SWP_FLAGS)
      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd ustawiania ciemnego paska tytułu Windows: #{e.message}"
      false
    end
  end
end
