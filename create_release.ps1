param(
    [string]$tagName = "",
    [string]$releaseTitle = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Extract version from sketchup_dark_mode.rb if not explicitly passed
$loaderContent = Get-Content (Join-Path $scriptDir "sketchup_dark_mode.rb") -Raw
if ($loaderContent -match "VERSION\s*=\s*'([^']+)'") {
    $ver = $matches[1]
} elseif ($loaderContent -match "ext\.version\s*=\s*'([^']+)'") {
    $ver = $matches[1]
} else {
    $ver = "1.1.2"
}

if (-not $tagName) {
    $tagName = "v$ver"
}
if (-not $releaseTitle) {
    $releaseTitle = "$tagName - Diagnostic Logging, Optional Tooltips & Stability"
}

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
$rbzPath = Join-Path $scriptDir "sketchup_dark_mode.rbz"
$versionedRbzPath = Join-Path $scriptDir "sketchup_dark_mode_v$ver.rbz"

if (-not (Test-Path $rbzPath)) {
    Write-Error "RBZ file not found at $rbzPath. Please run build_rbz.ps1 first."
    exit 1
}

$releaseNotesPath = Join-Path $scriptDir "RELEASE_NOTES.md"
if (-not (Test-Path $releaseNotesPath)) {
    Write-Error "RELEASE_NOTES.md not found at $releaseNotesPath"
    exit 1
}
$releaseBody = [System.IO.File]::ReadAllText($releaseNotesPath, [System.Text.Encoding]::UTF8)

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

    # Delete existing rbz assets if present to re-upload fresh
    if ($existingRelease.assets) {
        foreach ($asset in $existingRelease.assets) {
            if ($asset.name -eq "sketchup_dark_mode.rbz" -or $asset.name -eq "sketchup_dark_mode_v$ver.rbz") {
                Write-Host "Deleting old asset $($asset.name) ($($asset.id)) before re-uploading..." -ForegroundColor Yellow
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

# 3. Upload helper function
function Upload-Asset($filePath, $assetName) {
    if (-not (Test-Path $filePath)) { return }
    $uploadUri = "https://uploads.github.com/repos/$repo/releases/$($releaseObj.id)/assets?name=$assetName"
    Write-Host "Uploading $assetName to GitHub..." -ForegroundColor Cyan
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $uploadHeaders = @{
        "Authorization"  = "Bearer $token"
        "User-Agent"     = "PowerShell-GitHub-Release"
        "Content-Type"   = "application/zip"
        "Content-Length" = $fileBytes.Length
    }
    $res = Invoke-RestMethod -Uri $uploadUri -Headers $uploadHeaders -Method Post -Body $fileBytes
    Write-Host " [SUCCESS] Uploaded $assetName -> $($res.browser_download_url)" -ForegroundColor Green
}

Upload-Asset $versionedRbzPath "sketchup_dark_mode_v$ver.rbz"
Upload-Asset $rbzPath "sketchup_dark_mode.rbz"

Write-Host " [SUCCESS] Release published successfully!" -ForegroundColor Green
Write-Host "Release URL: $($releaseObj.html_url)" -ForegroundColor Green
