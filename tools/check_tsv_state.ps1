# check_tsv_state.ps1 - ASCII only. Literaly czytane z tools\tmp\literale_35.txt
# Stan 9 TSV + duplikaty. Wynik -> tools\tmp\check_tsv_state.txt
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$i18n = Join-Path $root 'i18n'
$tmpd = Join-Path $root 'tools\tmp'
$out = Join-Path $tmpd 'check_tsv_state.txt'
$litFile = Join-Path $tmpd 'literale_35.txt'

$lits = @(Get-Content -Encoding UTF8 $litFile | Where-Object { $_.Trim() -ne '' })

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("STAN 9 TSV + DUPLIKATY (Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm'))")

$langFiles = @('english','polish','czech','french','german','italian','spanish','portuguese','afrikaans')

foreach ($lf in $langFiles) {
  $p = Join-Path $i18n "$lf.tsv"
  if (-not (Test-Path $p)) { [void]$sb.AppendLine("BRAK PLIKU: $lf.tsv"); continue }
  $lines = Get-Content -Encoding UTF8 $p
  $maxId = -1
  $lastText = ''
  foreach ($l in $lines) {
    $pp = $l -split "`t", 2
    if ($pp.Count -ge 1) {
      $id = 0
      if ([int]::TryParse($pp[0], [ref]$id)) {
        if ($id -gt $maxId) { $maxId = $id; $lastText = $pp[1] }
      }
    }
  }
  [void]$sb.AppendLine("$lf.tsv: linii=$($lines.Count) maxID=$maxId  ($lastText)")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("DUPLIKATY (litera? wystepujacy juz w ktoryms TSV):")
$dupCount = 0
foreach ($lit in $lits) {
  $hit = $null
  foreach ($lf in $langFiles) {
    $p = Join-Path $i18n "$lf.tsv"
    if (-not (Test-Path $p)) { continue }
    foreach ($l in (Get-Content -Encoding UTF8 $p)) {
      $pp = $l -split "`t", 2
      if ($pp.Count -ge 2) {
        if ($pp[1] -eq $lit) { $hit = "$lf.tsv (ID $($pp[0]))"; break }
      }
    }
    if ($hit) { break }
  }
  if ($hit) {
    $dupCount++
    [void]$sb.AppendLine("  DUPLIKAT: [$lit]  <- $hit")
  }
}
[void]$sb.AppendLine("Liczba duplikatow: $dupCount")

$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Write-Host "Saved: $out"