# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module QtStyler
    extend self

    @initialized = false
    @available = false
    @default_palette_saved = false
    @default_palette_mem = nil

    # Inicjalizuje wskaźniki do funkcji Qt 6 przez Fiddle
    def initialize_qt
      return @available if @initialized
      @initialized = true

      su_dir = File.dirname(Sketchup.find_support_file('sketchup.exe'))

      # Załaduj biblioteki Qt 6
      qt_core_handle = load_dll('Qt6Core.dll', su_dir)
      qt_gui_handle = load_dll('Qt6Gui.dll', su_dir)
      qt_widgets_handle = load_dll('Qt6Widgets.dll', su_dir)

      unless qt_core_handle && qt_gui_handle && qt_widgets_handle
        puts '[Dark Mode] Nie odnaleziono wszystkich bibliotek Qt 6.'
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

      # 6. QPalette QGuiApplication::palette()
      @fn_get_palette = Fiddle::Function.new(
        qt_gui_handle['?palette@QGuiApplication@@SA?AVQPalette@@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 7. QPalette::QPalette()
      @fn_palette_ctor = Fiddle::Function.new(
        qt_gui_handle['??0QPalette@@QEAA@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 8. QPalette::~QPalette()
      @fn_palette_dtor = Fiddle::Function.new(
        qt_gui_handle['??1QPalette@@QEAA@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 9. void QPalette::setColor(ColorRole, const QColor&)
      @fn_palette_set_color = Fiddle::Function.new(
        qt_gui_handle['?setColor@QPalette@@QEAAXW4ColorRole@1@AEBVQColor@@@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 10. QColor::QColor(const char*)
      @fn_qcolor_ctor = Fiddle::Function.new(
        qt_gui_handle['??0QColor@@QEAA@PEBD@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 11. QWidget* QApplication::activeWindow()
      @fn_active_window = Fiddle::Function.new(
        qt_widgets_handle['?activeWindow@QApplication@@SAPEAVQWidget@@XZ'],
        [],
        Fiddle::TYPE_VOIDP
      )

      # 12. WId QWidget::winId()
      @fn_widget_winid = Fiddle::Function.new(
        qt_widgets_handle['?winId@QWidget@@QEBA_KXZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_LONG_LONG
      )

      # Zachowaj domyślną paletę przy pierwszym uruchomieniu
      save_default_palette

      @available = true
      puts '[Dark Mode] Pomyślnie zainicjalizowano interfejs Fiddle dla Qt 6 (Palette + Stylesheet + WinId).'
      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd Fiddle podczas ładowania Qt: #{e.message}"
      @available = false
      false
    end

    def available?
      initialize_qt
      @available
    end

    # Pobiera HWND aktywnego okna Qt
    def active_window_hwnd
      return nil unless available?

      w = @fn_active_window.call
      return nil if w.nil? || w.to_i == 0

      hwnd = @fn_widget_winid.call(w)
      hwnd.to_i
    rescue StandardError
      nil
    end

    # Nakłada ciemną paletę systemową na całą aplikację Qt
    def apply_dark_palette
      return unless available?

      pal_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| pal_mem[i] = 0 }
      @fn_palette_ctor.call(pal_mem)

      color_mem = Fiddle::Pointer.malloc(32)

      # Role barw w Qt::ColorRole:
      # WindowText=0, Button=1, Light=2, Midlight=3, Dark=4, Mid=5,
      # Text=6, BrightText=7, ButtonText=8, Base=9, Window=10, Shadow=11,
      # Highlight=12, HighlightedText=13, Link=14, AlternateBase=16,
      # ToolTipBase=18, ToolTipText=19, PlaceholderText=20
      dark_roles = {
        0  => '#d4d4d4', # WindowText
        1  => '#2d2d30', # Button
        2  => '#3e3e42', # Light
        3  => '#2d2d30', # Midlight
        4  => '#1a1a1c', # Dark
        5  => '#282828', # Mid
        6  => '#d4d4d4', # Text
        7  => '#ffffff', # BrightText
        8  => '#d4d4d4', # ButtonText
        9  => '#1e1e1e', # Base (tło widoków list, ikon, edytorów)
        10 => '#252526', # Window (tło tacek, okien, paneli)
        11 => '#141414', # Shadow
        12 => '#094771', # Highlight
        13 => '#ffffff', # HighlightedText
        14 => '#3794ff', # Link
        16 => '#252526', # AlternateBase
        18 => '#2d2d30', # ToolTipBase
        19 => '#f1f1f1', # ToolTipText
        20 => '#808080'  # PlaceholderText
      }

      dark_roles.each do |role, hex|
        32.times { |i| color_mem[i] = 0 }
        cstr = Fiddle::Pointer.to_ptr(hex + "\0")
        @fn_qcolor_ctor.call(color_mem, cstr)
        @fn_palette_set_color.call(pal_mem, role, color_mem)
      end

      # Zastosuj paletę globalnie do całej aplikacji
      @fn_set_palette.call(pal_mem, 0)
    rescue StandardError => e
      puts "[Dark Mode] Błąd ustawiania ciemnej palety Qt: #{e.message}"
    ensure
      @fn_palette_dtor.call(pal_mem) if pal_mem
    end

    # Przywraca oryginalną paletę
    def restore_default_palette
      return unless available? && @default_palette_saved && @default_palette_mem

      @fn_set_palette.call(@default_palette_mem, 0)
    rescue StandardError => e
      puts "[Dark Mode] Błąd przywracania palety: #{e.message}"
    end

    # Aplikuje arkusz stylów CSS oraz ciemną paletę do całej aplikacji Qt
    def apply_stylesheet(css_text)
      return false unless available?

      # 1. Zastosuj ciemną paletę
      apply_dark_palette

      # 2. Zastosuj arkusz stylów QSS
      qapp = @fn_instance.call
      if qapp.nil? || qapp.to_i == 0
        puts '[Dark Mode] Wskaźnik QApplication jest pusty (NULL).'
        return false
      end

      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }

      c_text = (css_text || '').encode('UTF-8') + "\0"
      c_ptr = Fiddle::Pointer.to_ptr(c_text)

      begin
        @fn_qstr_ctor.call(qstr_buf, c_ptr)
        @fn_set_stylesheet.call(qapp, qstr_buf)
      ensure
        @fn_qstr_dtor.call(qstr_buf)
      end

      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd nakładania stylu Qt: #{e.message}"
      false
    end

    # Przywraca domyślny wygląd (czyści arkusz stylów i przywraca jasną paletę)
    def clear_stylesheet
      return false unless available?

      restore_default_palette

      qapp = @fn_instance.call
      return false if qapp.nil? || qapp.to_i == 0

      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }
      c_ptr = Fiddle::Pointer.to_ptr("\0")

      begin
        @fn_qstr_ctor.call(qstr_buf, c_ptr)
        @fn_set_stylesheet.call(qapp, qstr_buf)
      ensure
        @fn_qstr_dtor.call(qstr_buf)
      end

      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd czyszczenia stylu Qt: #{e.message}"
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

    def save_default_palette
      return if @default_palette_saved

      @default_palette_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| @default_palette_mem[i] = 0 }
      @fn_get_palette.call(@default_palette_mem)
      @default_palette_saved = true
    rescue StandardError => e
      puts "[Dark Mode] Nie udało się zachować domyślnej palety: #{e.message}"
    end
  end
end
