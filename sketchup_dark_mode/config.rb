# frozen_string_literal: true

require 'json'
require 'win32/registry' rescue nil

module SketchupDarkMode
  module Config
    extend self

    CONFIG_FILE = File.join(
      ENV['APPDATA'] || File.expand_path('~'),
      'SketchUp',
      'SketchUp 2025',
      'SketchUp',
      'sketchup_dark_mode_config.json'
    )

    DEFAULT_SETTINGS = {
      'dark_mode_enabled'   => true,
      'style_ui'            => true,
      'style_titlebar'      => true,
      'style_viewport'      => true,
      'dark_materials_list' => true,
      'auto_sync_windows'   => false,
      'viewport_bg_hex'     => '#1e1e20',
      'viewport_edge_hex'   => '#dedee0',
      'auto_hot_reload'     => false,
      'language'            => 'auto'
    }.freeze

    @settings = nil

    def settings
      @settings ||= load_settings
    end

    def [](key)
      settings[key.to_s]
    end

    def []=(key, value)
      settings[key.to_s] = value
      save_settings
    end

    def load_settings
      if File.exist?(CONFIG_FILE)
        begin
          data = JSON.parse(File.read(CONFIG_FILE))
          DEFAULT_SETTINGS.merge(data)
        rescue StandardError => e
          puts "[Dark Mode] Error reading configuration: #{e.message}, restoring defaults"
          DEFAULT_SETTINGS.dup
        end
      else
        cfg = DEFAULT_SETTINGS.dup
        # Check if Windows uses dark mode
        if windows_dark_mode?
          cfg['dark_mode_enabled'] = true
        end
        cfg
      end
    end

    def save_settings
      dir = File.dirname(CONFIG_FILE)
      Dir.mkdir(dir) unless Dir.exist?(dir)
      File.write(CONFIG_FILE, JSON.pretty_generate(settings))
    rescue StandardError => e
      puts "[Dark Mode] Error saving configuration: #{e.message}"
    end

    # Detects whether Windows 10/11 uses dark mode
    def windows_dark_mode?
      return false unless defined?(Win32::Registry)

      Win32::Registry::HKEY_CURRENT_USER.open('SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize') do |reg|
        _type, val = reg.read('AppsUseLightTheme')
        return val == 0
      end
    rescue StandardError
      false
    end
  end
end
