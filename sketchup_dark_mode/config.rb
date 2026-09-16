# frozen_string_literal: true

require 'json'
require 'win32/registry' rescue nil

module SketchupDarkMode
  module Config
    extend self

    def config_file
      plugins_dir = Sketchup.find_support_file('Plugins') rescue nil
      if plugins_dir && Dir.exist?(plugins_dir)
        File.join(File.expand_path('..', plugins_dir), 'sketchup_dark_mode_config.json')
      else
        su_year = (Sketchup.respond_to?(:version) ? Sketchup.version.to_i : 2025)
        su_year = 2025 if su_year < 2000
        File.join(ENV['APPDATA'] || File.expand_path('~'), 'SketchUp', "SketchUp #{su_year}", 'SketchUp', 'sketchup_dark_mode_config.json')
      end
    end

    DEFAULT_SETTINGS = {
      'dark_mode_enabled'   => false,
      'style_ui'            => true,
      'style_titlebar'      => true,
      'style_viewport'      => true,
      'dark_materials_list' => true,
      'style_tooltips'      => false,
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
      target_file = config_file
      if File.exist?(target_file)
        begin
          data = JSON.parse(File.read(target_file))
          DEFAULT_SETTINGS.merge(data)
        rescue StandardError => e
          puts "[Dark Mode] Error reading configuration: #{e.message}, restoring defaults"
          DEFAULT_SETTINGS.dup
        end
      else
        DEFAULT_SETTINGS.dup
      end
    end

    def save_settings
      target_file = config_file
      dir = File.dirname(target_file)
      Dir.mkdir(dir) unless Dir.exist?(dir)
      File.write(target_file, JSON.pretty_generate(settings))
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
