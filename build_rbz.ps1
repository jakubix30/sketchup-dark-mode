# Build script for SketchUp Dark Mode (.rbz extension package)
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Extract version from sketchup_dark_mode.rb
$loaderContent = Get-Content (Join-Path $scriptDir "sketchup_dark_mode.rb") -Raw
if ($loaderContent -match "ext\.version\s*=\s*'([^']+)'") {
    $version = $matches[1]
} else {
    $version = "1.0.0"
}

$versionedRbzPath = Join-Path $scriptDir "sketchup_dark_mode_v$version.rbz"
$rbzPath = Join-Path $scriptDir "sketchup_dark_mode.rbz"

if (Test-Path $versionedRbzPath) {
    Remove-Item $versionedRbzPath -Force
}
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

    # 3. Create .rbz archive (versioned)
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $tempDir,
        $versionedRbzPath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    # Copy to generic name as well
    Copy-Item $versionedRbzPath -Destination $rbzPath -Force

    $sizeKb = [math]::Round(((Get-Item $versionedRbzPath).Length / 1KB), 2)
    Write-Host " [SUCCESS] Built versioned package: $versionedRbzPath ($sizeKb KB)" -ForegroundColor Green
    Write-Host " [SUCCESS] Copied package to:      $rbzPath" -ForegroundColor Green
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
}
