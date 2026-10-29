$targets = @(
    "C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins",
    "C:\Users\jakub\Downloads\schizza262\SketchUp Pro 2026 v26.2.243 Portable\Sandbox\SketchUp 2026\roaming\modified\@APPDATA@\SketchUp\SketchUp 2026\SketchUp\Plugins"
)

foreach ($pluginsDir in $targets) {
    if (Test-Path $pluginsDir) {
        $destDir = Join-Path $pluginsDir "sketchup_dark_mode"
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
        Copy-Item -Path "D:\Projects\sketchup-dark-mode\sketchup_dark_mode\*" -Destination $destDir -Recurse -Force
        Copy-Item -Path "D:\Projects\sketchup-dark-mode\sketchup_dark_mode.rb" -Destination $pluginsDir -Force
        Write-Host " [SUCCESS] Copied to: $pluginsDir" -ForegroundColor Green
    }
}
