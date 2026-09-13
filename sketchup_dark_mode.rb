# frozen_string_literal: true
# ==============================================================================
# SketchUp Dark Mode Extension
# Modern Dark Mode for SketchUp 2025 (Qt 6 UI + DWM Titlebar + 3D Viewport)
# ==============================================================================

require 'sketchup.rb'
require 'extensions.rb'

module SketchupDarkMode
  PLUGIN_DIR = File.dirname(__FILE__)
  EXTENSION_ID = 'SketchupDarkMode'

  unless file_loaded?(__FILE__)
    ext = SketchupExtension.new('SketchUp Dark Mode', File.join(PLUGIN_DIR, 'sketchup_dark_mode', 'loader'))
    ext.description = 'Nowoczesny tryb ciemny (Dark Mode) dla SketchUp 2025 – stylizuje interfejs Qt6, pasek tytułu Windows oraz obszar roboczy 3D.'
    ext.version     = '1.0.0'
    ext.creator     = 'Antigravity'
    ext.copyright   = '2026'

    Sketchup.register_extension(ext, true)
    file_loaded(__FILE__)
  end
end
