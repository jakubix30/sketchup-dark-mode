# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module QtStyler
    extend self

    @available = false

    # Inicjalizuje wskaźniki do funkcji Qt 6 przez Fiddle
    def initialize_qt
      if @available && @fn_set_palette && @fn_palette_ctor && @fn_qcolor_ctor && @fn_palette_set_color
        return true
      end

      su_dir = File.dirname(Sketchup.find_support_file('sketchup.exe'))

      # Załaduj biblioteki Qt 6
      qt_core_handle    = load_dll('Qt6Core.dll', su_dir)
      qt_gui_handle     = load_dll('Qt6Gui.dll', su_dir)
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
        sym_pal = qt_widgets_handle['?palette@QApplication@@SA?AVQPalette@@XZ']
        @fn_get_palette = Fiddle::Function.new(sym_pal, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP) if sym_pal
      rescue StandardError
        @fn_get_palette = nil
      end

      @available = true
      puts '[Dark Mode] Pomyślnie zainicjalizowano interfejs Fiddle dla Qt 6 (Paleta + QSS).'
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

    def capture_original_palette
      return if @orig_palette_saved
      if @fn_get_palette
        @orig_palette_mem = Fiddle::Pointer.malloc(128)
        128.times { |i| @orig_palette_mem[i] = 0 }
        @fn_get_palette.call(@orig_palette_mem)
        @orig_palette_saved = true
      end
    rescue StandardError => e
      @orig_palette_mem = nil
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

    # Nakłada ciemną paletę systemową na całą aplikację Qt
    def apply_dark_palette
      return unless available?

      capture_original_palette

      pal_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| pal_mem[i] = 0 }
      @fn_palette_ctor.call(pal_mem)

      color_mem = Fiddle::Pointer.malloc(32)

      # Definicje barw ciemnego motywu w Qt
      dark_roles = {
        0  => '#d4d4d4', # WindowText (jasny tekst dla etykiet, okien i paneli np. Cienie)
        1  => '#2d2d30', # Button
        2  => '#3e3e42', # Light
        3  => '#2d2d30', # Midlight
        4  => '#1a1a1c', # Dark
        5  => '#282828', # Mid
        6  => '#000000', # Text (czarny tekst dla widoków próbek i folderów materiałów)
        7  => '#ffffff', # BrightText
        8  => '#ffffff', # ButtonText
        9  => '#1e1e1e', # Base (tło kafelków, miniatur, list)
        10 => '#252526', # Window (tło okien, paneli, tacek)
        11 => '#141414', # Shadow
        12 => '#094771', # Highlight (zaznaczenie)
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

      # Zastosuj paletę globalnie
      @fn_set_palette.call(pal_mem, 0)
    rescue StandardError => e
      puts "[Dark Mode] Błąd ustawiania ciemnej palety: #{e.message}"
    ensure
      @fn_palette_dtor.call(pal_mem) if pal_mem
    end

    # Przywraca standardową jasną paletę systemową Windows
    def restore_default_palette
      return unless available?

      if @orig_palette_saved && @orig_palette_mem
        @fn_set_palette.call(@orig_palette_mem, 0)
        return
      end

      pal_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| pal_mem[i] = 0 }
      @fn_palette_ctor.call(pal_mem)
      @fn_set_palette.call(pal_mem, 0)
    rescue StandardError => e
      puts "[Dark Mode] Błąd przywracania jasnej palety: #{e.message}"
    ensure
      @fn_palette_dtor.call(pal_mem) if pal_mem && !@orig_palette_saved
    end

    # Aplikuje arkusz stylów CSS oraz ciemną paletę
    def apply_stylesheet(css_text)
      return false unless available?

      # 1. Zastosuj ciemną paletę
      apply_dark_palette

      # 2. Zastosuj arkusz stylów QSS
      qapp = @fn_instance.call
      if qapp.nil? || qapp.to_i == 0
        puts '[Dark Mode] Wskaźnik QApplication jest NULL.'
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

    # Ultra-lekki styl dla trybu jasnego odblokowujący szerokość zasobnika bez gwiazdek '*' (zero lagów)
    LIGHT_TRAY_QSS = <<~QSS
      CDockingTray,
      CDockingTrayDialog,
      CDockingPanel,
      CDockingPanelContainer,
      CPanelContentSplitter,
      KDDockWidgets--DockWidget,
      KDDockWidgets--FrameWidget,
      KDDockWidgets--SideBarWidget,
      KDDockWidgets--TabBarWidget,
      KDDockWidgets--TabWidgetWidget,
      QDockWidget,
      CMaterialBrowser,
      CMaterialBrowserPage,
      MaterialsBrowser,
      MaterialsBrowser2 {
          min-width: 0px !important;
      }

      CMaterialBrowserPreview {
          min-width: 0px !important;
          max-width: 100% !important;
      }
    QSS

    # Przywraca standardowy jasny motyw z odblokowanym zasobnikiem (ultra-lekki QSS bez gwiazdek *)
    def clear_stylesheet
      return false unless available?

      restore_default_palette

      qapp = @fn_instance.call
      return false if qapp.nil? || qapp.to_i == 0

      # Aplikujemy ultra-lekki styl odblokowujący szerokość zasobnika bez narzutu na silnik Qt
      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }
      c_text = LIGHT_TRAY_QSS.encode('UTF-8') + "\0"
      c_ptr = Fiddle::Pointer.to_ptr(c_text)

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
  end
end
