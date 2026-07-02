$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$cargo = Join-Path $HOME ".cargo\bin\cargo.exe"
if (-not (Test-Path $cargo)) {
  throw "cargo.exe not found"
}

& $cargo build --release --bin jireh-accelerator
Start-Process -FilePath ".\target\release\jireh-accelerator.exe" -ArgumentList "start" -Verb RunAs
