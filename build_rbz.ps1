# Build script for SketchUp Dark Mode (.rbz extension package)
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rbzPath = Join-Path $scriptDir "sketchup_dark_mode.rbz"

if (Test-Path $rbzPath) {
    Remove-Item $rbzPath -Force
}

$tempDir = Join-Path $env:TEMP "sketchup_dark_mode_build_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    # 1. Copy root ruby loader
    Copy-Item (Join-Path $scriptDir "sketchup_dark_mode.rb") -Destination $tempDir

    # 2. Copy extension directory
    $destModuleDir = Join-Path $tempDir "sketchup_dark_mode"
    New-Item -ItemType Directory -Path $destModuleDir | Out-Null

    # Copy ruby source files
    Get-ChildItem -Path (Join-Path $scriptDir "sketchup_dark_mode") -Filter "*.rb" | ForEach-Object {
        Copy-Item $_.FullName -Destination $destModuleDir
    }

    # Copy icons
    Copy-Item (Join-Path $scriptDir "sketchup_dark_mode\icons") -Destination $destModuleDir -Recurse

    # Copy styles
    Copy-Item (Join-Path $scriptDir "sketchup_dark_mode\styles") -Destination $destModuleDir -Recurse

    # 3. Create .rbz archive
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $tempDir,
        $rbzPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    $sizeKb = [math]::Round(((Get-Item $rbzPath).Length / 1KB), 2)
    Write-Host " [SUCCESS] Built extension package: $rbzPath ($sizeKb KB)" -ForegroundColor Green
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
}
