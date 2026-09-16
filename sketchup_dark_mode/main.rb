# frozen_string_literal: true

require 'sketchup.rb'

module SketchupDarkMode
  module Main
    extend self

    QSS_PATH = File.join(PLUGIN_DIR, 'sketchup_dark_mode', 'styles', 'dark_theme.qss')
    ICONS_DIR = File.join(PLUGIN_DIR, 'sketchup_dark_mode', 'icons')

    @app_observer = nil
    @toolbar = nil
    @cmd_toggle = nil
    @cmd_restore = nil

    class DarkModeAppObserver < Sketchup::AppObserver
      def onNewModel(model)
        Main.on_model_changed(model)
      end

      def onOpenModel(model)
        Main.on_model_changed(model)
      end

      def onActivateModel(model)
        Main.on_model_changed(model)
      end
    end

    def init
      su_ver = (Sketchup.respond_to?(:version) ? Sketchup.version : 'unknown')
      Logger.info("[Init] SketchUp Dark Mode v#{VERSION} initializing on SketchUp #{su_ver} (#{RUBY_PLATFORM})") if defined?(Logger)
      Logger.info("[Config] Current settings: #{Config.settings.to_json rescue Config.settings.to_s}") if defined?(Logger)

      # Auto sync with Windows theme if enabled
      if Config['auto_sync_windows']
        Config['dark_mode_enabled'] = Config.windows_dark_mode?
        Logger.info("[Config] Auto-sync Windows theme: dark_mode_enabled set to #{Config['dark_mode_enabled']}") if defined?(Logger)
      end

      setup_ui
      setup_observers

      # Only auto-apply dark mode on launch if it was explicitly enabled previously
      if dark_mode_active?
        Logger.info('[Init] Dark mode is active in config. Scheduling 1.0s startup timer...') if defined?(Logger)
        UI.start_timer(1.0, false) do
          if dark_mode_active?
            Logger.info('[Init] Startup timer fired. Applying dark mode...') if defined?(Logger)
            enable_dark_mode
          end
        end
      else
        Logger.info('[Init] Dark mode is inactive on startup. Loaded in clean Light Mode.') if defined?(Logger)
      end
    end

    def dark_mode_active?
      Config['dark_mode_enabled'] == true
    end

    def toggle
      if dark_mode_active?
        disable_dark_mode
      else
        enable_dark_mode
      end
    end

    def enable_dark_mode
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f
      Logger.info('[Action] Enabling dark mode...') if defined?(Logger)
      Config['dark_mode_enabled'] = true
      Config['auto_sync_windows'] = false

      # 1. Windows titlebar (DWM)
      if Config['style_titlebar']
        Logger.info('[Action] Step 1/3: Applying DWM dark titlebar...') if defined?(Logger)
        DwmStyler.set_dark_titlebar(true)
      end

      # 2. Qt 6 UI (Dark palette + QSS)
      if Config['style_ui']
        Logger.info('[Action] Step 2/3: Applying Qt 6 UI styling (palette + QSS)...') if defined?(Logger)
        apply_current_qss
      else
        Logger.info('[Action] Step 2/3: style_ui is false. Clearing Qt stylesheet...') if defined?(Logger)
        QtStyler.clear_stylesheet
      end

      # 3. 3D Viewport
      if Config['style_viewport']
        Logger.info('[Action] Step 3/3: Applying dark 3D viewport style...') if defined?(Logger)
        ViewportStyler.apply_dark_viewport(Sketchup.active_model)
      else
        Logger.info('[Action] Step 3/3: style_viewport is false. Restoring viewport...') if defined?(Logger)
        ViewportStyler.restore_viewport(Sketchup.active_model)
      end

      update_ui_elements
      t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f
      elapsed_ms = ((t1 - t0) * 1000).round(1)
      Logger.info("[Action] Dark mode ENABLED in #{elapsed_ms}ms.") if defined?(Logger)
      puts '[Dark Mode] Dark mode ENABLED.'
    rescue StandardError => e
      Logger.error('[Action] Error enabling dark mode', e) if defined?(Logger)
      puts "[Dark Mode] Error enabling dark mode: #{e.message}"
    end

    def disable_dark_mode
      Logger.info('[Action] Disabling dark mode and restoring default light theme...') if defined?(Logger)
      Config['dark_mode_enabled'] = false
      Config['auto_sync_windows'] = false

      # 1. Windows titlebar (DWM)
      Logger.info('[Action] Step 1/3: Restoring DWM light titlebar...') if defined?(Logger)
      DwmStyler.set_dark_titlebar(false)

      # 2. 3D Viewport (Restore default canvas colors)
      Logger.info('[Action] Step 2/3: Restoring default 3D viewport canvas...') if defined?(Logger)
      ViewportStyler.restore_viewport(Sketchup.active_model)

      # 3. Qt 6 UI (Restore light palette and clear QSS)
      Logger.info('[Action] Step 3/3: Restoring Qt light palette and clearing QSS...') if defined?(Logger)
      QtStyler.clear_stylesheet

      update_ui_elements
      Logger.info('[Action] Restored default light theme successfully.') if defined?(Logger)
      puts '[Dark Mode] Restored default light theme.'
    rescue StandardError => e
      Logger.error('[Action] Error disabling dark mode', e) if defined?(Logger)
      puts "[Dark Mode] Error disabling dark mode: #{e.message}"
    end

    def update_state
      if dark_mode_active?
        enable_dark_mode
      else
        disable_dark_mode
      end
    end

    def reload_stylesheet
      loader_dir = File.dirname(__FILE__)
      load File.join(loader_dir, 'qt_styler.rb')
      load File.join(loader_dir, 'main.rb')
      if File.exist?(QSS_PATH)
        puts "[Dark Mode] #{I18n.t(:cmd_reload)} (#{QSS_PATH})..."
        if dark_mode_active? && Config['style_ui']
          apply_current_qss
        end
        UI.messagebox(I18n.t(:reload_success), MB_OK)
      else
        UI.messagebox(I18n.t(:reload_error, path: QSS_PATH), MB_OK)
      end
    end

    def on_model_changed(model)
      if dark_mode_active? && Config['style_viewport']
        ViewportStyler.apply_dark_viewport(model)
      end
    end

    def apply_current_qss
      if File.exist?(QSS_PATH)
        qss_content = File.read(QSS_PATH, encoding: 'UTF-8')
        icons_dir = ICONS_DIR.tr('\\', '/')
        qss_content = qss_content.gsub('{{ICONS_DIR}}', icons_dir)
        QtStyler.apply_stylesheet(qss_content)
      else
        puts "[Dark Mode] Warning: Stylesheet #{QSS_PATH} does not exist."
      end
    end

    private

    def update_ui_elements
      return unless @cmd_toggle

      is_dark = dark_mode_active?
      icon_suffix = is_dark ? '_active' : ''

      svg_icon = File.join(ICONS_DIR, "dark_mode#{icon_suffix}.svg")
      png_24   = File.join(ICONS_DIR, "dark_mode#{icon_suffix}_24.png")
      png_32   = File.join(ICONS_DIR, "dark_mode#{icon_suffix}_32.png")

      if File.exist?(svg_icon)
        @cmd_toggle.small_icon = svg_icon
        @cmd_toggle.large_icon = svg_icon
      elsif File.exist?(png_24) && File.exist?(png_32)
        @cmd_toggle.small_icon = png_24
        @cmd_toggle.large_icon = png_32
      end

      status_msg = is_dark ? I18n.t(:status_on) : I18n.t(:status_off)
      @cmd_toggle.tooltip = status_msg if @cmd_toggle
      @cmd_toggle.status_bar_text = status_msg if @cmd_toggle
    end

    def setup_ui
      # 1. Toggle command
      @cmd_toggle = UI::Command.new(I18n.t(:cmd_toggle)) do
        Main.toggle
      end
      @cmd_toggle.menu_text = I18n.t(:cmd_toggle_menu)
      @cmd_toggle.tooltip = I18n.t(:cmd_toggle_tip)
      @cmd_toggle.status_bar_text = I18n.t(:cmd_toggle_status)

      @cmd_toggle.set_validation_proc do
        if defined?(MF_CHECKED) && defined?(MF_UNCHECKED)
          Main.dark_mode_active? ? MF_CHECKED : MF_UNCHECKED
        else
          Main.dark_mode_active? ? 1 : 0
        end
      end

      update_ui_elements

      # 2. Restore default (Light mode) command
      @cmd_restore = UI::Command.new(I18n.t(:cmd_restore)) do
        Main.disable_dark_mode
      end
      @cmd_restore.menu_text = I18n.t(:cmd_restore_menu)
      @cmd_restore.tooltip = I18n.t(:cmd_restore_tip)
      @cmd_restore.status_bar_text = I18n.t(:cmd_restore_status)

      sun_svg = File.join(ICONS_DIR, 'light_mode.svg')
      sun_24  = File.join(ICONS_DIR, 'light_mode_24.png')
      sun_32  = File.join(ICONS_DIR, 'light_mode_32.png')

      if File.exist?(sun_svg)
        @cmd_restore.small_icon = sun_svg
        @cmd_restore.large_icon = sun_svg
      elsif File.exist?(sun_24) && File.exist?(sun_32)
        @cmd_restore.small_icon = sun_24
        @cmd_restore.large_icon = sun_32
      end

      # 3. Toggle dark 3D viewport command
      cmd_toggle_viewport = UI::Command.new(I18n.t(:cmd_viewport)) do
        Config['style_viewport'] = !Config['style_viewport']
        if Config['style_viewport'] && Main.dark_mode_active?
          ViewportStyler.apply_dark_viewport(Sketchup.active_model)
        else
          ViewportStyler.restore_viewport(Sketchup.active_model)
        end
      end
      cmd_toggle_viewport.menu_text = I18n.t(:cmd_viewport_menu)
      cmd_toggle_viewport.tooltip = I18n.t(:cmd_viewport_tip)
      cmd_toggle_viewport.status_bar_text = I18n.t(:cmd_viewport_status)
      cmd_toggle_viewport.set_validation_proc do
        if defined?(MF_CHECKED) && defined?(MF_UNCHECKED)
          Config['style_viewport'] ? MF_CHECKED : MF_UNCHECKED
        else
          Config['style_viewport'] ? 1 : 0
        end
      end

      # 4. Toggle dark materials list command
      cmd_toggle_materials = UI::Command.new(I18n.t(:cmd_materials)) do
        Config['dark_materials_list'] = !Config['dark_materials_list']
        Main.apply_current_qss if Main.dark_mode_active?
      end
      cmd_toggle_materials.menu_text = I18n.t(:cmd_materials_menu)
      cmd_toggle_materials.tooltip = I18n.t(:cmd_materials_tip)
      cmd_toggle_materials.status_bar_text = I18n.t(:cmd_materials_status)
      cmd_toggle_materials.set_validation_proc do
        if defined?(MF_CHECKED) && defined?(MF_UNCHECKED)
          Config['dark_materials_list'] ? MF_CHECKED : MF_UNCHECKED
        else
          Config['dark_materials_list'] ? 1 : 0
        end
      end

      # 5. Settings command
      cmd_settings = UI::Command.new(I18n.t(:cmd_settings)) do
        SettingsDialog.show
      end
      cmd_settings.menu_text = I18n.t(:cmd_settings_menu)
      cmd_settings.tooltip = I18n.t(:cmd_settings_tip)

      # 6. Reload stylesheet (Hot-Reload) command
      cmd_reload = UI::Command.new(I18n.t(:cmd_reload)) do
        Main.reload_stylesheet
      end
      cmd_reload.menu_text = I18n.t(:cmd_reload_menu)
      cmd_reload.tooltip = I18n.t(:cmd_reload_tip)

      # 7. Diagnostic log command
      cmd_log = UI::Command.new(I18n.t(:cmd_log)) do
        Logger.open_log_file
      end
      cmd_log.menu_text = I18n.t(:cmd_log_menu)
      cmd_log.tooltip = I18n.t(:cmd_log_tip)

      # Menu in Extensions
      menu = UI.menu('Plugins').add_submenu(I18n.t(:menu_title))
      menu.add_item(@cmd_toggle)
      menu.add_item(@cmd_restore)
      menu.add_separator
      menu.add_item(cmd_toggle_viewport)
      menu.add_item(cmd_toggle_materials)
      menu.add_separator
      menu.add_item(cmd_settings)
      menu.add_separator
      menu.add_item(cmd_reload)
      menu.add_item(cmd_log)

      # Toolbar - single toggle button
      @toolbar = UI::Toolbar.new(I18n.t(:toolbar_title))
      @toolbar.add_item(@cmd_toggle)
      @toolbar.restore
    end

    def setup_observers
      @app_observer ||= DarkModeAppObserver.new
      Sketchup.add_observer(@app_observer)
    end
  end
end
