# frozen_string_literal: true

module SketchupDarkMode
  module Logger
    extend self

    def log_path
      cfg_file = (Config.config_file rescue nil)
      if cfg_file
        File.join(File.dirname(cfg_file), 'sketchup_dark_mode.log')
      else
        su_year = (Sketchup.respond_to?(:version) ? Sketchup.version.to_i : 2025)
        su_year = 2025 if su_year < 2000
        File.join(ENV['APPDATA'] || File.expand_path('~'), 'SketchUp', "SketchUp #{su_year}", 'SketchUp', 'sketchup_dark_mode.log')
      end
    end

    def log(level, message)
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
      entry = "[#{timestamp}] [#{level}] #{message}"

      # Also output to Ruby Console
      puts "[Dark Mode] #{message}" rescue nil

      # Immediate flush to disk so crashes leave a trail
      target = log_path
      return unless target

      dir = File.dirname(target)
      Dir.mkdir(dir) unless Dir.exist?(dir)

      # Rotate log if larger than 1MB
      if File.exist?(target) && File.size(target) > 1_048_576
        File.rename(target, "#{target}.old") rescue nil
      end

      File.open(target, 'a:UTF-8') do |f|
        f.puts(entry)
        f.flush
      end
    rescue StandardError
      # Never crash host application due to logging
    end

    def info(msg)
      log('INFO', msg)
    end

    def warn(msg)
      log('WARN', msg)
    end

    def error(msg, exception = nil)
      if exception
        log('ERROR', "#{msg}: #{exception.class} - #{exception.message}\n#{exception.backtrace&.first(5)&.join("\n")}")
      else
        log('ERROR', msg)
      end
    end

    def open_log_file
      path = log_path
      if File.exist?(path)
        UI.openURL("file:///#{path.tr('\\', '/')}")
      else
        UI.messagebox("Log file not found yet at:\n#{path}", MB_OK)
      end
    end
  end
end
