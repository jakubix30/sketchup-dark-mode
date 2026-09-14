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

    # Enables or disables Windows dark titlebar for all SketchUp windows
    def set_dark_titlebar(enable = true)
      kernel32 = Fiddle.dlopen('kernel32.dll')
      user32   = Fiddle.dlopen('user32.dll')
      dwmapi   = Fiddle.dlopen('dwmapi.dll')

      fn_get_pid      = Fiddle::Function.new(kernel32['GetCurrentProcessId'], [], Fiddle::TYPE_INT)
      fn_enum_windows = Fiddle::Function.new(user32['EnumWindows'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
      fn_get_wnd_pid  = Fiddle::Function.new(user32['GetWindowThreadProcessId'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
      fn_is_visible   = Fiddle::Function.new(user32['IsWindowVisible'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
      fn_set_pos      = Fiddle::Function.new(user32['SetWindowPos'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
      fn_dwm_attr     = Fiddle::Function.new(dwmapi['DwmSetWindowAttribute'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)

      my_pid = fn_get_pid.call
      pid_buf = [0].pack('L')
      val = enable ? 1 : 0
      pv_attr = [val].pack('L')

      # Get window from Qt if available
      if defined?(QtStyler) && QtStyler.respond_to?(:active_window_hwnd)
        qt_hwnd = QtStyler.active_window_hwnd
        if qt_hwnd && qt_hwnd > 0
          apply_dark_to_hwnd(qt_hwnd, fn_dwm_attr, fn_set_pos, pv_attr)
        end
      end

      # EnumWindows: find all visible windows belonging to SketchUp process (main window, Ruby Console, dialogs)
      enum_callback = Fiddle::Closure::BlockCaller.new(Fiddle::TYPE_INT, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP]) do |hwnd, _|
        fn_get_wnd_pid.call(hwnd, pid_buf)
        wnd_pid = pid_buf.unpack1('L')

        if wnd_pid == my_pid && fn_is_visible.call(hwnd) != 0
          apply_dark_to_hwnd(hwnd, fn_dwm_attr, fn_set_pos, pv_attr)
        end
        1 # Continue enumeration
      end

      fn_enum_windows.call(enum_callback, 0)
      true
    rescue StandardError => e
      puts "[Dark Mode] Error setting Windows dark titlebar: #{e.message}"
      false
    end

    private

    def apply_dark_to_hwnd(hwnd, fn_dwm_attr, fn_set_pos, pv_attr)
      # First try attribute 20 (Windows 11 / newer Windows 10)
      hr = fn_dwm_attr.call(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, pv_attr, 4)
      if hr != 0
        # For older Windows 10 builds fallback to attribute 19
        fn_dwm_attr.call(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, pv_attr, 4)
      end
      # Force refresh non-client frame (titlebar)
      fn_set_pos.call(hwnd, 0, 0, 0, 0, 0, SWP_FLAGS)
    end
  end
end
