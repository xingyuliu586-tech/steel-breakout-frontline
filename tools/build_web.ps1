param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [string]$Version = "0.1.0"
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$godot = (Resolve-Path -LiteralPath $GodotExe).Path
$build = Join-Path $root "build/web"
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $build, $dist | Out-Null

function Invoke-Godot {
    param([string[]]$Arguments)
    & $godot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot failed with exit code $LASTEXITCODE" }
}

Push-Location $root
try {
    Invoke-Godot @("--headless", "--editor", "--path", $root, "--quit")
    Invoke-Godot @("--headless", "--path", $root, "res://tests/release_smoke.tscn")
    Invoke-Godot @("--headless", "--path", $root, "--export-release", "Web", (Join-Path $build "index.html"))
    foreach ($name in @("index.html", "index.js", "index.wasm", "index.pck")) {
        if (-not (Test-Path -LiteralPath (Join-Path $build $name))) {
            throw "Missing Web export file: $name"
        }
    }
    New-Item -ItemType File -Path (Join-Path $build ".nojekyll") -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $root "docs/PLAY-WEB.txt") -Destination (Join-Path $build "READ-ME.txt") -Force
    Copy-Item -LiteralPath (Join-Path $root "docs/ASSETS.md") -Destination $build -Force
    $licenseTarget = Join-Path $build "licenses"
    New-Item -ItemType Directory -Force -Path $licenseTarget | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $root "licenses") -File -Filter "*.txt" |
        Copy-Item -Destination $licenseTarget -Force
    $zip = Join-Path $dist "SteelBreakout-v$Version-Web.zip"
    Compress-Archive -Path "$build/*" -DestinationPath $zip -CompressionLevel Optimal -Force
    $hash = Get-FileHash -LiteralPath $zip -Algorithm SHA256
    "$($hash.Hash.ToLower())  $([IO.Path]::GetFileName($zip))" |
        Set-Content -LiteralPath (Join-Path $dist "SHA256SUMS-Web.txt") -Encoding ascii
    Write-Output "Web package: $zip"
} finally {
    Pop-Location
}
