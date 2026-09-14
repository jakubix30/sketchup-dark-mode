# frozen_string_literal: true

require 'sketchup.rb'

module SketchupDarkMode
  loader_dir = File.dirname(__FILE__)

  # Use load instead of require to allow seamless reloading during development in the Ruby Console
  load File.join(loader_dir, 'config.rb')
  load File.join(loader_dir, 'i18n.rb')
  load File.join(loader_dir, 'qt_styler.rb')
  load File.join(loader_dir, 'dwm_styler.rb')
  load File.join(loader_dir, 'viewport_styler.rb')
  load File.join(loader_dir, 'settings_dialog.rb')
  load File.join(loader_dir, 'color_picker_dialog.rb')
  load File.join(loader_dir, 'main.rb')

  unless file_loaded?(__FILE__)
    Main.init
    file_loaded(__FILE__)
  else
    # If the file is reloaded, refresh current state
    Main.update_state
  end
end
