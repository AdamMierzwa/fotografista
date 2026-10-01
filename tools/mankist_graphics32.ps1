param([string]$Root)

$ErrorActionPreference = 'Stop'

if(-not $Root){
  $Root = Join-Path (Split-Path -Parent $PSScriptRoot) 'Lib\Graphics32\Source'
}

if(-not (Test-Path -LiteralPath $Root)){
  Write-Output "BRAK katalogu: $Root"
  exit 1
}

# Manifest jest liczony po normalizacji koncow linii (CRLF/CR -> LF),
# dzieki czemu working tree, index i klon daja ten sam wynik.
# Sortowanie ordinalne - niezalezne od locale systemu.
$sha = [System.Security.Cryptography.SHA256]::Create()
$files = @(Get-ChildItem -LiteralPath $Root -Recurse -File)
$lines = New-Object System.Collections.Generic.List[string]

foreach($f in $files){
  $rel = $f.FullName.Substring($Root.Length + 1) -replace '\\','/'
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $text  = [System.Text.Encoding]::UTF8.GetString($bytes)
  $text  = [System.Text.RegularExpressions.Regex]::Replace($text,"`r`n|`r","`n")
  $norm  = [System.Text.Encoding]::UTF8.GetBytes($text)
  $h     = (($sha.ComputeHash($norm)) | ForEach-Object { $_.ToString('x2') }) -join ''
  $lines.Add("$rel`t$h")
}

$arr = $lines.ToArray()
[Array]::Sort($arr, [StringComparer]::Ordinal)
$payload  = [System.Text.Encoding]::UTF8.GetBytes((($arr -join "`n") + "`n"))
$manifest = (($sha.ComputeHash($payload)) | ForEach-Object { $_.ToString('x2') }) -join ''

Write-Output "plikow: $($arr.Length)"
Write-Output "sha256: $manifest"