$pluginsDir = "C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins"
$destDir = Join-Path $pluginsDir "sketchup_dark_mode"

Copy-Item -Path "D:\Projects\sketchup-dark-mode\sketchup_dark_mode\*" -Destination $destDir -Recurse -Force
Copy-Item -Path "D:\Projects\sketchup-dark-mode\sketchup_dark_mode.rb" -Destination $pluginsDir -Force

Write-Host "Copied to SketchUp 2025 Plugins folder successfully!"
