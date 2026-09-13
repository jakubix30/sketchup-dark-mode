# frozen_string_literal: true

require 'sketchup.rb'

module SketchupDarkMode
  loader_dir = File.dirname(__FILE__)

  require File.join(loader_dir, 'config')
  require File.join(loader_dir, 'qt_styler')
  require File.join(loader_dir, 'dwm_styler')
  require File.join(loader_dir, 'viewport_styler')
  require File.join(loader_dir, 'settings_dialog')
  require File.join(loader_dir, 'main')

  unless file_loaded?(__FILE__)
    Main.init
    file_loaded(__FILE__)
  end
end
