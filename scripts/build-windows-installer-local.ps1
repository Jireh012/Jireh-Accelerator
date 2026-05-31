$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$nsisSource = 'C:\Program Files (x86)\NSIS'
if (-not (Test-Path -LiteralPath $nsisSource)) {
  throw "NSIS was not found at: $nsisSource"
}

$toolsRoot = Join-Path $env:LOCALAPPDATA '.cargo-packager'
$nsisTarget = Join-Path $toolsRoot 'NSIS'
$tempDir = Join-Path $env:TEMP 'linuxdo-nsis-plugins'

New-Item -ItemType Directory -Force -Path $toolsRoot, $tempDir | Out-Null

if (Test-Path -LiteralPath $nsisTarget) {
  $resolvedTarget = (Resolve-Path -LiteralPath $nsisTarget).Path
  $resolvedTools = (Resolve-Path -LiteralPath $toolsRoot).Path
  if (-not $resolvedTarget.StartsWith($resolvedTools, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove unexpected path: $resolvedTarget"
  }
  Remove-Item -LiteralPath $nsisTarget -Recurse -Force
}

Copy-Item -LiteralPath $nsisSource -Destination $nsisTarget -Recurse -Force

$plugins = Join-Path $nsisTarget 'Plugins'
$unicodePlugins = Join-Path $plugins 'x86-unicode'
New-Item -ItemType Directory -Force -Path $unicodePlugins | Out-Null

$appIdZip = Join-Path $tempDir 'NSIS-ApplicationID.zip'
$utilsDll = Join-Path $tempDir 'nsis_tauri_utils.dll'

curl.exe -L -k --retry 5 --retry-delay 2 --fail `
  -o $appIdZip `
  'https://github.com/tauri-apps/binary-releases/releases/download/nsis-plugins-v0/NSIS-ApplicationID.zip'

curl.exe -L -k --retry 5 --retry-delay 2 --fail `
  -o $utilsDll `
  'https://github.com/tauri-apps/nsis-tauri-utils/releases/download/nsis_tauri_utils-v0.2.1/nsis_tauri_utils.dll'

$utilsHash = (Get-FileHash -LiteralPath $utilsDll -Algorithm SHA1).Hash.ToUpperInvariant()
if ($utilsHash -ne '53A7CFAEB6A4A9653D6D5FBFF02A3C3B8720130A') {
  throw "nsis_tauri_utils.dll hash mismatch: $utilsHash"
}

Expand-Archive -LiteralPath $appIdZip -DestinationPath $plugins -Force
Copy-Item -LiteralPath (Join-Path $plugins 'ReleaseUnicode\ApplicationID.dll') `
  -Destination (Join-Path $unicodePlugins 'ApplicationID.dll') `
  -Force
Copy-Item -LiteralPath $utilsDll `
  -Destination (Join-Path $unicodePlugins 'nsis_tauri_utils.dll') `
  -Force

Get-Item `
  (Join-Path $nsisTarget 'makensis.exe'), `
  (Join-Path $nsisTarget 'Bin\makensis.exe'), `
  (Join-Path $unicodePlugins 'ApplicationID.dll'), `
  (Join-Path $unicodePlugins 'nsis_tauri_utils.dll')

cargo packager -f nsis

Get-ChildItem -Path (Join-Path $repoRoot 'dist') -Filter '*setup.exe' | Sort-Object LastWriteTime -Descending
