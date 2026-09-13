# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module QtStyler
    extend self

    @initialized = false
    @available = false

    # Inicjalizuje wskaźniki do funkcji Qt 6 przez Fiddle
    def initialize_qt
      return @available if @initialized
      @initialized = true

      su_dir = File.dirname(Sketchup.find_support_file('sketchup.exe'))

      # Załaduj Qt6Core.dll
      qt_core_handle = nil
      begin
        qt_core_handle = Fiddle.dlopen('Qt6Core.dll')
      rescue StandardError
        core_path = File.join(su_dir, 'Qt6Core.dll')
        qt_core_handle = Fiddle.dlopen(core_path) if File.exist?(core_path)
      end

      # Załaduj Qt6Widgets.dll
      qt_widgets_handle = nil
      begin
        qt_widgets_handle = Fiddle.dlopen('Qt6Widgets.dll')
      rescue StandardError
        widgets_path = File.join(su_dir, 'Qt6Widgets.dll')
        qt_widgets_handle = Fiddle.dlopen(widgets_path) if File.exist?(widgets_path)
      end

      unless qt_core_handle && qt_widgets_handle
        puts '[Dark Mode] Nie odnaleziono modułów Qt 6.'
        @available = false
        return false
      end

      # 1. QCoreApplication::instance()
      # Sygnatura MSVC: ?instance@QCoreApplication@@SAPEAV1@XZ
      @fn_instance = Fiddle::Function.new(
        qt_core_handle['?instance@QCoreApplication@@SAPEAV1@XZ'],
        [],
        Fiddle::TYPE_VOIDP
      )

      # 2. QString::QString(const char*)
      # Sygnatura MSVC: ??0QString@@QEAA@PEBD@Z
      # RCX = this (bufor pamięci na obiekt QString), RDX = const char* (napis w UTF-8)
      @fn_qstr_ctor = Fiddle::Function.new(
        qt_core_handle['??0QString@@QEAA@PEBD@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOIDP
      )

      # 3. QString::~QString()
      # Sygnatura MSVC: ??1QString@@QEAA@XZ
      # RCX = this
      @fn_qstr_dtor = Fiddle::Function.new(
        qt_core_handle['??1QString@@QEAA@XZ'],
        [Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      # 4. void QApplication::setStyleSheet(const QString&)
      # Sygnatura MSVC: ?setStyleSheet@QApplication@@QEAAXAEBVQString@@@Z
      # RCX = this (qApp), RDX = const QString&
      @fn_set_stylesheet = Fiddle::Function.new(
        qt_widgets_handle['?setStyleSheet@QApplication@@QEAAXAEBVQString@@@Z'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_VOID
      )

      @available = true
      puts '[Dark Mode] Pomyślnie zainicjalizowano interfejs Fiddle dla Qt 6.'
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

    # Aplikuje arkusz stylów CSS do całej aplikacji Qt
    def apply_stylesheet(css_text)
      return false unless available?

      qapp = @fn_instance.call
      if qapp.nil? || qapp.to_i == 0
        puts '[Dark Mode] Wskaźnik QApplication jest pusty (NULL).'
        return false
      end

      # Alokacja 64 bajtów dla obiektu QString w pamięci natywnej
      qstr_buf = Fiddle::Pointer.malloc(64)
      64.times { |i| qstr_buf[i] = 0 }

      # Wskaźnik do tekstu C null-terminated
      c_text = (css_text || '').encode('UTF-8') + "\0"
      c_ptr = Fiddle::Pointer.to_ptr(c_text)

      begin
        # Wywołaj konstruktor QString(const char*)
        @fn_qstr_ctor.call(qstr_buf, c_ptr)

        # Wywołaj QApplication::setStyleSheet(const QString&)
        @fn_set_stylesheet.call(qapp, qstr_buf)
      ensure
        # Zawsze zwolnij zasoby QString przez destruktor
        @fn_qstr_dtor.call(qstr_buf)
      end

      true
    rescue StandardError => e
      puts "[Dark Mode] Błąd nakładania stylu Qt: #{e.message}"
      false
    end

    # Przywraca domyślny wygląd (czyści arkusz stylów)
    def clear_stylesheet
      apply_stylesheet('')
    end
  end
end
