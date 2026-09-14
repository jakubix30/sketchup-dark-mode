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

      # 13. QSplitter::setChildrenCollapsible(bool)
      begin
        sym = qt_widgets_handle['?setChildrenCollapsible@QSplitter@@QEAAX_N@Z']
        @fn_splitter_set_children_collapsible = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_CHAR], Fiddle::TYPE_VOID
        )
      rescue StandardError
        @fn_splitter_set_children_collapsible = nil
      end

      # 14. QSplitter::setCollapsible(int, bool)
      begin
        sym = qt_widgets_handle['?setCollapsible@QSplitter@@QEAAXH_N@Z']
        @fn_splitter_set_collapsible = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_CHAR], Fiddle::TYPE_VOID
        )
      rescue StandardError
        @fn_splitter_set_collapsible = nil
      end

      # 15. int QSplitter::count()
      begin
        sym = qt_widgets_handle['?count@QSplitter@@QEBAHXZ']
        @fn_splitter_count = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT
        )
      rescue StandardError
        @fn_splitter_count = nil
      end

      # 16. void QWidget::setMinimumWidth(int)
      begin
        sym = qt_widgets_handle['?setMinimumWidth@QWidget@@QEAAXH@Z']
        @fn_set_min_w = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_VOID
        )
      rescue StandardError
        @fn_set_min_w = nil
      end

      # 17. void QWidget::setMinimumSize(int, int)
      begin
        sym = qt_widgets_handle['?setMinimumSize@QWidget@@QEAAXHH@Z']
        @fn_set_min_size = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_VOID
        )
      rescue StandardError
        @fn_set_min_size = nil
      end

      # 18. const QMetaObject* QObject::metaObject()
      begin
        sym = qt_core_handle['?metaObject@QObject@@UEBAPEBUQMetaObject@@XZ']
        @fn_meta_object = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP
        )
      rescue StandardError
        @fn_meta_object = nil
      end

      # 19. const char* QMetaObject::className()
      begin
        sym = qt_core_handle['?className@QMetaObject@@QEBAPEBDXZ']
        @fn_class_name = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP
        )
      rescue StandardError
        @fn_class_name = nil
      end

      # 20. const QList<QObject*>& QObject::children()
      begin
        sym = qt_core_handle['?children@QObject@@QEBAAEBV?$QList@PEAVQObject@@@@XZ']
        @fn_children = Fiddle::Function.new(
          sym, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP
        )
      rescue StandardError
        @fn_children = nil
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

      # Definicje barw ciemnego motywu w Qt
      dark_roles = {
        0  => '#d4d4d4', # WindowText
        1  => '#2d2d30', # Button
        2  => '#3e3e42', # Light
        3  => '#2d2d30', # Midlight
        4  => '#1a1a1c', # Dark
        5  => '#282828', # Mid
        6  => '#ffffff', # Text (biały/jasny tekst)
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

      pal_mem = Fiddle::Pointer.malloc(128)
      128.times { |i| pal_mem[i] = 0 }
      @fn_palette_ctor.call(pal_mem)

      color_mem = Fiddle::Pointer.malloc(32)

      # Domyślne jasne barwy Windows
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
        9  => '#ffffff', # Base (białe tło)
        10 => '#f0f0f0', # Window (jasnoszary)
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
    rescue StandardError => e
      puts "[Dark Mode] Błąd przywracania jasnej palety: #{e.message}"
    ensure
      @fn_palette_dtor.call(pal_mem) if pal_mem
    end

    # Usuwa wszelkie limity minimalnej szerokości zasobnika (zarówno w trybie ciemnym, jak i domyślnym)
    def unlock_tray_limits(root = nil)
      return unless available?

      root ||= @fn_active_window.call
      return if root.nil? || root.to_i == 0

      visited = {}
      queue = [root]

      while (w = queue.shift)
        break if visited.size > 2000
        addr = w.to_i
        next if addr == 0 || visited[addr]
        visited[addr] = true

        cname = widget_class_name(w)

        # 1. Jeśli to QSplitter - odblokuj pełne zwijanie i brak minimalnych limitów dzieci
        if cname == 'QSplitter'
          @fn_splitter_set_children_collapsible&.call(w, 1)
          if @fn_splitter_count && @fn_splitter_set_collapsible
            cnt = @fn_splitter_count.call(w)
            cnt.times { |i| @fn_splitter_set_collapsible.call(w, i, 1) }
          end
        end

        # 2. Jeśli to doki, tacki, panele lub widoki materiałów - zresetuj minimumWidth i minimumSize
        if cname.include?('Splitter') || cname.include?('Dock') || cname.include?('Tray') ||
           cname.include?('Material') || cname.include?('ContentBrowser') ||
           cname.include?('ScrollArea') || cname.include?('Page') || cname.include?('FrameWidget') ||
           cname.include?('Button') || cname.include?('TabBar') || cname.include?('SideBar')
          @fn_set_min_w&.call(w, 0)
          @fn_set_min_size&.call(w, 0, 0)
        end

        # Pobierz i dodaj dzieci do kolejki przeszukiwania
        kids = object_children(w)
        queue.concat(kids) unless kids.empty?
      end
    rescue StandardError => e
      puts "[Dark Mode] Ostrzeżenie unlock_tray_limits: #{e.message}"
    end

    def widget_class_name(qobj)
      return '' if qobj.nil? || qobj.to_i == 0 || @fn_meta_object.nil? || @fn_class_name.nil?

      meta = @fn_meta_object.call(qobj)
      return '' if meta.nil? || meta.to_i == 0

      name_ptr = @fn_class_name.call(meta)
      return '' if name_ptr.nil? || name_ptr.to_i == 0

      name_ptr.to_s
    rescue StandardError
      ''
    end

    def object_children(qobj)
      return [] if qobj.nil? || qobj.to_i == 0 || @fn_children.nil?

      ref_ptr = @fn_children.call(qobj)
      return [] if ref_ptr.nil? || ref_ptr.to_i == 0

      # QList<QObject*> w Qt 6 (QArrayDataPointer):
      # offset 0: d (8B), offset 8: ptr (8B), offset 16: size (8B)
      bytes = ref_ptr[0, 24]
      return [] unless bytes && bytes.length >= 24

      elem_ptr_val = bytes[8, 8].unpack1('Q')
      size_val     = bytes[16, 8].unpack1('q')

      return [] if size_val <= 0 || size_val > 5000 || elem_ptr_val == 0

      elem_mem = Fiddle::Pointer.new(elem_ptr_val, size_val * 8)
      children_ptrs = []
      size_val.times do |i|
        child_addr = elem_mem[i * 8, 8].unpack1('Q')
        children_ptrs << Fiddle::Pointer.new(child_addr) if child_addr != 0
      end
      children_ptrs
    rescue StandardError
      []
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

      # 3. Odblokuj pełne zwijanie i limity szerokości zasobnika
      unlock_tray_limits

      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd nakładania stylu Qt: #{e.message}"
      false
    end

    # Przywraca domyślny wygląd (czyści styl i przywraca jasną paletę)
    def clear_stylesheet
      return false unless available?

      restore_default_palette

      qapp = @fn_instance.call
      return false if qapp.nil? || qapp.to_i == 0

      # Czyścimy arkusz stylów do zera (pełne przywrócenie natywnego stylu Windows)
      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }
      c_ptr = Fiddle::Pointer.to_ptr("\0")

      begin
        @fn_qstr_ctor.call(qstr_buf, c_ptr)
        @fn_set_stylesheet.call(qapp, qstr_buf)
      ensure
        @fn_qstr_dtor.call(qstr_buf)
      end

      # Odblokuj ograniczenia szerokości zasobnika również w trybie jasnym
      unlock_tray_limits

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
