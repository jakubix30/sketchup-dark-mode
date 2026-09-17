# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module QtStyler
    extend self

    @available = false

    # Initializes pointers to Qt 6 functions via Fiddle
    def initialize_qt
      if @available && @fn_set_palette && @fn_palette_ctor && @fn_qcolor_ctor && @fn_palette_set_color
        return true
      end

      su_exe = (Sketchup.find_support_file('sketchup.exe') rescue nil)
      su_dir = su_exe ? File.dirname(su_exe) : '.'

      # Load Qt 6 libraries
      qt_core_handle    = load_dll('Qt6Core.dll', su_dir)
      qt_gui_handle     = load_dll('Qt6Gui.dll', su_dir)
      qt_widgets_handle = load_dll('Qt6Widgets.dll', su_dir)

      unless qt_core_handle && qt_gui_handle && qt_widgets_handle
        puts '[Dark Mode] Could not find all Qt 6 libraries.'
        @available = false
        return false
      end

      # 1. QCoreApplication::instance()
      @fn_instance = Fiddle::Function.new(
        qt_core_handle['?instance@QCoreApplication@@SAPEAV1@XZ'],
        [],
        Fiddle::TYPE_VOIDP
      )

      # 2. QString::QString(const char*)
      @fn_qstr_ctor = Fiddle::Function.new(
        qt_core_handle['??0QString@@QEAA@PEBD@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 3. QString::~QString()
      @fn_qstr_dtor = Fiddle::Function.new(
        qt_core_handle['??1QString@@QEAA@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 4. void QApplication::setStyleSheet(const QString&)
      @fn_set_stylesheet = Fiddle::Function.new(
        qt_widgets_handle['?setStyleSheet@QApplication@@QEAAXAEBVQString@@@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 5. void QApplication::setPalette(const QPalette&, const char* = nullptr)
      @fn_set_palette = Fiddle::Function.new(
        qt_widgets_handle['?setPalette@QApplication@@SAXAEBVQPalette@@PEBD@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 6. QPalette::QPalette()
      @fn_palette_ctor = Fiddle::Function.new(
        qt_gui_handle['??0QPalette@@QEAA@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 7. QPalette::~QPalette()
      @fn_palette_dtor = Fiddle::Function.new(
        qt_gui_handle['??1QPalette@@QEAA@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 8. void QPalette::setColor(ColorRole, const QColor&)
      @fn_palette_set_color = Fiddle::Function.new(
        qt_gui_handle['?setColor@QPalette@@QEAAXW4ColorRole@1@AEBVQColor@@@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 9. QColor::QColor(const char*)
      @fn_qcolor_ctor = Fiddle::Function.new(
        qt_gui_handle['??0QColor@@QEAA@PEBD@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 10. QWidget* QApplication::activeWindow()
      @fn_active_window = Fiddle::Function.new(
        qt_widgets_handle['?activeWindow@QApplication@@SAPEAVQWidget@@XZ'],
        [],
        Fiddle::TYPE_VOIDP
      )

      # 11. WId QWidget::winId()
      @fn_widget_winid = Fiddle::Function.new(
        qt_widgets_handle['?winId@QWidget@@QEBA_KXZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_LONG_LONG
      )

      # 12. void QMainWindow::setCorner(Qt::Corner, Qt::DockWidgetArea)
      begin
        sym_corner = qt_widgets_handle['?setCorner@QMainWindow@@QEAAXW4Corner@Qt@@W4DockWidgetArea@3@@Z']
        @fn_set_corner = Fiddle::Function.new(
          sym_corner,
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT],
          Fiddle::TYPE_VOID
        )
      rescue StandardError
        @fn_set_corner = nil
      end

      begin
        sym_pal = qt_gui_handle['?palette@QGuiApplication@@SA?AVQPalette@@XZ']
        @fn_get_palette = Fiddle::Function.new(sym_pal, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP) if sym_pal
      rescue StandardError
        @fn_get_palette = nil
      end

      # 13. void QToolTip::setPalette(const QPalette&)
      begin
        sym_tt_set_pal = qt_widgets_handle['?setPalette@QToolTip@@SAXAEBVQPalette@@@Z']
        @fn_tooltip_set_palette = Fiddle::Function.new(sym_tt_set_pal, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID) if sym_tt_set_pal
      rescue StandardError
        @fn_tooltip_set_palette = nil
      end

      # 14. QPalette QToolTip::palette()
      begin
        sym_tt_get_pal = qt_widgets_handle['?palette@QToolTip@@SA?AVQPalette@@XZ']
        @fn_tooltip_get_palette = Fiddle::Function.new(sym_tt_get_pal, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP) if sym_tt_get_pal
      rescue StandardError
        @fn_tooltip_get_palette = nil
      end

      # 15. QObject RTTI (metaObject, className, inherits)
      begin
        sym_meta     = qt_core_handle['?metaObject@QObject@@UEBAPEBUQMetaObject@@XZ']
        sym_name     = qt_core_handle['?className@QMetaObject@@QEBAPEBDXZ']
        sym_inherits = qt_core_handle['?inherits@QObject@@QEBA_NPEBD@Z']

        @fn_meta_object = Fiddle::Function.new(sym_meta, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP) if sym_meta
        @fn_class_name  = Fiddle::Function.new(sym_name, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP) if sym_name
        @fn_inherits    = Fiddle::Function.new(sym_inherits, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_CHAR) if sym_inherits
      rescue StandardError
        @fn_meta_object = nil
        @fn_class_name  = nil
        @fn_inherits    = nil
      end

      @available = true
      capture_original_palette
      Logger.info('[QtStyler] Successfully initialized Qt 6 Fiddle interface (Palette + QSS).') if defined?(Logger)
      puts '[Dark Mode] Successfully initialized Qt 6 Fiddle interface (Palette + QSS).'
      true
    rescue StandardError => e
      Logger.error('[QtStyler] Fiddle error during Qt initialization', e) if defined?(Logger)
      puts "[Dark Mode] Fiddle error during Qt initialization: #{e.message}"
      @available = false
      false
    end

    def available?
      initialize_qt
      @available
    end

    def capture_original_palette
      return if @orig_palette_saved
      if @fn_get_palette
        @orig_palette_mem = Fiddle::Pointer.malloc(128)
        128.times { |i| @orig_palette_mem[i] = 0 }
        @fn_get_palette.call(@orig_palette_mem)
        @orig_palette_saved = true
      end
      if Config['style_tooltips'] && @fn_tooltip_get_palette && !@orig_tooltip_palette_saved
        @orig_tooltip_palette_mem = Fiddle::Pointer.malloc(128)
        128.times { |i| @orig_tooltip_palette_mem[i] = 0 }
        @fn_tooltip_get_palette.call(@orig_tooltip_palette_mem)
        @orig_tooltip_palette_saved = true
      end
    rescue StandardError => e
      Logger.error('[QtStyler] Error capturing original palette', e) if defined?(Logger)
      @orig_palette_mem = nil
      @orig_tooltip_palette_mem = nil
    end

    def active_window_hwnd
      return nil unless available?

      w = @fn_active_window.call
      return nil if w.nil? || w.to_i == 0

      hwnd = @fn_widget_winid.call(w)
      hwnd.to_i
    rescue StandardError
      nil
    end

    # Applies dark system palette to the entire Qt application
    def apply_dark_palette
      return unless available?

      Logger.info('[QtStyler] Applying dark palette to QApplication...') if defined?(Logger)
      capture_original_palette

      pal_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| pal_mem[i] = 0 }
      @fn_palette_ctor.call(pal_mem)

      color_mem = Fiddle::Pointer.malloc(32)

      # Dark theme color definitions in Qt
      dark_roles = {
        0  => '#d4d4d4', # WindowText (light text for labels, windows, and panels e.g. Shadows)
        1  => '#2d2d30', # Button
        2  => '#3e3e42', # Light
        3  => '#2d2d30', # Midlight
        4  => '#1a1a1c', # Dark
        5  => '#282828', # Mid
        6  => '#ffffff', # Text
        7  => '#ffffff', # BrightText
        8  => '#ffffff', # ButtonText
        9  => '#1e1e1e', # Base (background for tiles, thumbnails, lists)
        10 => '#252526', # Window (background for windows, panels, trays)
        11 => '#141414', # Shadow
        12 => '#094771', # Highlight (selection)
        13 => '#ffffff', # HighlightedText
        14 => '#3794ff', # Link
        16 => '#252526', # AlternateBase
        18 => '#252526', # ToolTipBase
        19 => '#ffffff', # ToolTipText
        20 => '#808080'  # PlaceholderText
      }

      dark_roles.each do |role, hex|
        32.times { |i| color_mem[i] = 0 }
        cstr = Fiddle::Pointer.to_ptr(hex + "\0")
        @fn_qcolor_ctor.call(color_mem, cstr)
        @fn_palette_set_color.call(pal_mem, role, color_mem)
      end

      # Apply palette globally
      @fn_set_palette.call(pal_mem, 0)

      # Explicitly apply dark palette to QToolTip with white text (if enabled in settings)
      if Config['style_tooltips'] && @fn_tooltip_set_palette
        tt_pal_mem = Fiddle::Pointer.malloc(128)
        128.times { |i| tt_pal_mem[i] = 0 }
        @fn_palette_ctor.call(tt_pal_mem)

        tt_roles = {
          0  => '#ffffff', # WindowText
          1  => '#252526', # Button
          6  => '#ffffff', # Text
          7  => '#ffffff', # BrightText
          8  => '#ffffff', # ButtonText
          9  => '#252526', # Base
          10 => '#252526', # Window
          12 => '#ffffff', # Highlight
          13 => '#ffffff', # HighlightedText
          14 => '#ffffff', # Link
          18 => '#252526', # ToolTipBase
          19 => '#ffffff'  # ToolTipText
        }

        tt_roles.each do |role, hex|
          32.times { |i| color_mem[i] = 0 }
          cstr = Fiddle::Pointer.to_ptr(hex + "\0")
          @fn_qcolor_ctor.call(color_mem, cstr)
          @fn_palette_set_color.call(tt_pal_mem, role, color_mem)
        end

        @fn_tooltip_set_palette.call(tt_pal_mem)
        @fn_palette_dtor.call(tt_pal_mem)
        Logger.info('[QtStyler] style_tooltips is TRUE. Applied dark palette to QToolTip.') if defined?(Logger)
      else
        Logger.info('[QtStyler] style_tooltips is FALSE. Bypassing QToolTip Fiddle calls.') if defined?(Logger)
      end

      @dark_palette_applied = true
      Logger.info('[QtStyler] Dark palette applied to QApplication successfully.') if defined?(Logger)
    rescue StandardError => e
      Logger.error('[QtStyler] Error applying dark palette', e) if defined?(Logger)
      puts "[Dark Mode] Error applying dark palette: #{e.message}"
    ensure
      @fn_palette_dtor.call(pal_mem) if pal_mem
    end

    # Restores default light Windows system palette
    def restore_default_palette
      return unless available?
      return unless @dark_palette_applied

      Logger.info('[QtStyler] Restoring light palette...') if defined?(Logger)
      if @orig_palette_saved && @orig_palette_mem
        @fn_set_palette.call(@orig_palette_mem, 0)
        if Config['style_tooltips'] && @orig_tooltip_palette_saved && @orig_tooltip_palette_mem && @fn_tooltip_set_palette
          @fn_tooltip_set_palette.call(@orig_tooltip_palette_mem)
        end
        @dark_palette_applied = false
        Logger.info('[QtStyler] Original light palette restored successfully.') if defined?(Logger)
        return
      end

      pal_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| pal_mem[i] = 0 }
      @fn_palette_ctor.call(pal_mem)
      color_mem = Fiddle::Pointer.malloc(32)

      # Default Windows light colors (fallback if no backup copy)
      light_roles = {
        0  => '#000000', # WindowText
        1  => '#f0f0f0', # Button
        2  => '#ffffff', # Light
        3  => '#e0e0e0', # Midlight
        4  => '#a0a0a0', # Dark
        5  => '#808080', # Mid
        6  => '#000000', # Text
        7  => '#ffffff', # BrightText
        8  => '#000000', # ButtonText
        9  => '#ffffff', # Base (white background)
        10 => '#f0f0f0', # Window (light gray)
        11 => '#696969', # Shadow
        12 => '#0078d7', # Highlight
        13 => '#ffffff', # HighlightedText
        14 => '#0066cc', # Link
        16 => '#f7f7f7', # AlternateBase
        18 => '#ffffdc', # ToolTipBase
        19 => '#000000', # ToolTipText
        20 => '#767676'  # PlaceholderText
      }

      light_roles.each do |role, hex|
        32.times { |i| color_mem[i] = 0 }
        cstr = Fiddle::Pointer.to_ptr(hex + "\0")
        @fn_qcolor_ctor.call(color_mem, cstr)
        @fn_palette_set_color.call(pal_mem, role, color_mem)
      end

      @fn_set_palette.call(pal_mem, 0)
      @dark_palette_applied = false
      Logger.info('[QtStyler] Fallback light palette restored successfully.') if defined?(Logger)
    rescue StandardError => e
      Logger.error('[QtStyler] Error restoring default light palette', e) if defined?(Logger)
      puts "[Dark Mode] Error restoring default light palette: #{e.message}"
    ensure
      @fn_palette_dtor.call(pal_mem) if pal_mem && !@orig_palette_saved
    end

    # Applies QSS stylesheet and dark palette
    def apply_stylesheet(css_text)
      return false unless available?

      # 1. Apply dark palette
      apply_dark_palette

      # 2. Check if QSS is enabled in settings
      if Config.key?('apply_qss') && !Config['apply_qss']
        Logger.info('[QtStyler] apply_qss is FALSE. Palette applied; bypassing QSS stylesheet.') if defined?(Logger)
        return true
      end

      # 3. Apply QSS stylesheet
      qapp = @fn_instance.call
      if qapp.nil? || qapp.to_i == 0
        Logger.error('[QtStyler] QApplication pointer is NULL.') if defined?(Logger)
        puts '[Dark Mode] QApplication pointer is NULL.'
        return false
      end

      # Verify qapp object type via Qt RTTI
      if @fn_meta_object && @fn_class_name
        begin
          meta = @fn_meta_object.call(qapp)
          if meta && meta.to_i != 0
            class_name = @fn_class_name.call(meta).to_s
            Logger.info("[QtStyler] qapp C++ class name: '#{class_name}'") if defined?(Logger)

            if @fn_inherits
              is_qapp = @fn_inherits.call(qapp, Fiddle::Pointer.to_ptr("QApplication\0")) != 0
              Logger.info("[QtStyler] qapp inherits QApplication: #{is_qapp}") if defined?(Logger)
              unless is_qapp
                Logger.warn("[QtStyler] qapp is '#{class_name}' (not a QApplication). Skipping QApplication::setStyleSheet to avoid crash.") if defined?(Logger)
                return true
              end
            end
          end
        rescue StandardError => err
          Logger.warn("[QtStyler] Could not inspect qapp RTTI: #{err.message}") if defined?(Logger)
        end
      end

      icons_dir = File.join(File.dirname(__FILE__), 'icons').tr('\\', '/')
      processed_css = (css_text || '').gsub('{{ICONS_DIR}}', icons_dir)
      Logger.info("[QtStyler] Applying QSS stylesheet (#{processed_css.bytesize} bytes)...") if defined?(Logger)

      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }

      c_text = processed_css.encode('UTF-8') + "\0"
      c_ptr = Fiddle::Pointer.to_ptr(c_text)

      begin
        @fn_qstr_ctor.call(qstr_buf, c_ptr)
        Logger.info('[QtStyler] QString constructed. Invoking QApplication::setStyleSheet...') if defined?(Logger)
        @fn_set_stylesheet.call(qapp, qstr_buf)
      ensure
        @fn_qstr_dtor.call(qstr_buf)
      end

      Logger.info('[QtStyler] QSS stylesheet applied successfully.') if defined?(Logger)
      true
    rescue StandardError => e
      Logger.error('[QtStyler] Error applying Qt stylesheet', e) if defined?(Logger)
      puts "[Dark Mode] Error applying Qt stylesheet: #{e.message}"
      false
    end

    # Completely disables Qt styling and restores 100% native factory look of SketchUp without CSS overhead
    def clear_stylesheet
      return false unless available?

      restore_default_palette

      qapp = @fn_instance.call
      return false if qapp.nil? || qapp.to_i == 0

      # If QSS was disabled or qapp is not a QApplication, nothing to clear in QSS
      if Config.key?('apply_qss') && !Config['apply_qss']
        return true
      end

      if @fn_inherits
        is_qapp = @fn_inherits.call(qapp, Fiddle::Pointer.to_ptr("QApplication\0")) != 0 rescue false
        return true unless is_qapp
      end

      Logger.info('[QtStyler] Clearing QSS stylesheet...') if defined?(Logger)

      # Clear stylesheet to empty string (full reset of QSS)
      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }
      c_ptr = Fiddle::Pointer.to_ptr("\0")

      begin
        @fn_qstr_ctor.call(qstr_buf, c_ptr)
        @fn_set_stylesheet.call(qapp, qstr_buf)
      ensure
        @fn_qstr_dtor.call(qstr_buf)
      end

      Logger.info('[QtStyler] QSS stylesheet cleared successfully.') if defined?(Logger)
      true
    rescue StandardError => e
      Logger.error('[QtStyler] Error clearing Qt stylesheet', e) if defined?(Logger)
      puts "[Dark Mode] Error clearing Qt stylesheet: #{e.message}"
      false
    end

    private

    def load_dll(dll_name, su_dir)
      begin
        Fiddle.dlopen(dll_name)
      rescue StandardError
        full_path = File.join(su_dir, dll_name)
        File.exist?(full_path) ? Fiddle.dlopen(full_path) : nil
      end
    end
  end
end
