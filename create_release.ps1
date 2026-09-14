$ErrorActionPreference = "Stop"

# 1. Retrieve GitHub PAT from Git Credential Manager
$inputStr = "protocol=https`nhost=github.com`n"
$credOutput = $inputStr | git credential fill
$token = ""
foreach ($line in $credOutput) {
    if ($line -match "^password=(.+)$") {
        $token = $matches[1]
    }
}

if (-not $token) {
    Write-Error "Could not retrieve GitHub PAT from git credential manager."
    exit 1
}

$repo = "jakubix30/sketchup-dark-mode"
$tagName = "v1.0.0"
$releaseTitle = "v1.0.0 - Modern Dark Mode for SketchUp 2025 (PL / EN)"
$rbzPath = "D:\Projects\sketchup-dark-mode\sketchup_dark_mode.rbz"

if (-not (Test-Path $rbzPath)) {
    Write-Error "RBZ file not found at $rbzPath"
    exit 1
}

$releaseBody = @"
## SketchUp Dark Mode v1.0.0 🌓

A modern Dark Mode extension for **SketchUp 2025** on Windows 10/11.

### 🌟 Features & Highlights
- **Full Qt 6 Dark Theme**: Restyles menus, toolbars, docking trays, status bars, tab bars, dialogs, and panels.
- **Windows DWM Dark Titlebar**: Native dark window titlebar matching the Windows 10/11 theme.
- **Dark 3D Viewport**: Optional dark canvas background with clear, high-contrast model edges.
- **Materials & Folders Readability**: Deep black, extra-bold text (font-weight: 800) elevated on folder swatches for crisp readability in dark mode.
- **Compact Tray Layout in Both Modes**: Unconstrained tray resizing allows shrinking the default tray down to 2–3 columns in both Dark and Light modes with zero lag.
- **Multilingual Support (PL / EN)**:
  - Full support for Polish and English.
  - Automatic language detection matching SketchUp's locale (`Sketchup.get_locale`).
  - Manual language switch (`Auto | English | Polski`) in Dark Mode Settings.
- **Hot-Reload Support**: Instant stylesheet reloading (`Reload CSS Stylesheet`) without restarting SketchUp.

---

### 📦 Installation
1. Download the **`sketchup_dark_mode.rbz`** file attached below.
2. In SketchUp 2025, navigate to:  
   **Extensions** -> **Extension Manager** (or **Rozszerzenia** -> **Menedżer rozszerzeń**).
3. Click **Install Extension** (**Zainstaluj rozszerzenie**) and select `sketchup_dark_mode.rbz`.
4. The extension will activate automatically and add a **Dark Mode** toolbar.
"@

$headers = @{
    "Authorization" = "Bearer $token"
    "User-Agent"    = "PowerShell-GitHub-Release"
    "Accept"        = "application/vnd.github+json"
}

# 2. Check if release already exists for this tag
Write-Host "Checking if release for tag $tagName exists..." -ForegroundColor Cyan
$existingRelease = $null
try {
    $existingRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/tags/$tagName" -Headers $headers -Method Get
    Write-Host "Found existing release ID: $($existingRelease.id)" -ForegroundColor Yellow
} catch {
    # 404 is expected if release does not exist yet
    Write-Host "No existing release for tag $tagName. Creating a new one..." -ForegroundColor Green
}

$releaseObj = $null
if ($existingRelease) {
    $releaseId = $existingRelease.id
    # Update release body and title
    $updatePayload = @{
        name = $releaseTitle
        body = $releaseBody
        draft = $false
        prerelease = $false
    } | ConvertTo-Json -Compress

    $releaseObj = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/$releaseId" -Headers $headers -Method Patch -Body ([System.Text.Encoding]::UTF8.GetBytes($updatePayload)) -ContentType "application/json; charset=utf-8"
    Write-Host "Updated existing release ID: $releaseId" -ForegroundColor Green

    # Delete existing rbz asset if present to re-upload fresh
    if ($existingRelease.assets) {
        foreach ($asset in $existingRelease.assets) {
            if ($asset.name -eq "sketchup_dark_mode.rbz") {
                Write-Host "Deleting old asset $($asset.id) before re-uploading..." -ForegroundColor Yellow
                Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/assets/$($asset.id)" -Headers $headers -Method Delete
            }
        }
    }
} else {
    $createPayload = @{
        tag_name         = $tagName
        target_commitish = "main"
        name             = $releaseTitle
        body             = $releaseBody
        draft            = $false
        prerelease       = $false
    } | ConvertTo-Json -Compress

    $releaseObj = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Headers $headers -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($createPayload)) -ContentType "application/json; charset=utf-8"
    Write-Host "Created new release with ID: $($releaseObj.id)" -ForegroundColor Green
}

# 3. Upload sketchup_dark_mode.rbz asset
$uploadUri = "https://uploads.github.com/repos/$repo/releases/$($releaseObj.id)/assets?name=sketchup_dark_mode.rbz"
Write-Host "Uploading $rbzPath to $uploadUri..." -ForegroundColor Cyan

$fileBytes = [System.IO.File]::ReadAllBytes($rbzPath)
$uploadHeaders = @{
    "Authorization"  = "Bearer $token"
    "User-Agent"     = "PowerShell-GitHub-Release"
    "Content-Type"   = "application/zip"
    "Content-Length" = $fileBytes.Length
}

$uploadedAsset = Invoke-RestMethod -Uri $uploadUri -Headers $uploadHeaders -Method Post -Body $fileBytes
Write-Host " [SUCCESS] Release created and published successfully!" -ForegroundColor Green
Write-Host "Release URL: $($releaseObj.html_url)" -ForegroundColor Green
Write-Host "Asset download URL: $($uploadedAsset.browser_download_url)" -ForegroundColor Green
