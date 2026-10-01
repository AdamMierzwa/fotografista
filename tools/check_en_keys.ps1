# check_en_keys.ps1 - ASCII only. Pary EN<TAB>PL czytane z proponowane_klucze.txt
# Sprawdza kolizje EN w english.tsv i duplikaty PL w polish.tsv.
# Wynik -> tools\tmp\check_en_keys.txt
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$i18n = Join-Path $root 'i18n'
$tmpd = Join-Path $root 'tools\tmp'
$out = Join-Path $tmpd 'check_en_keys.txt'
$pairsFile = Join-Path $tmpd 'proponowane_klucze.txt'

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("CHECK EN-KLUCZY vs english.tsv (duplikaty EN = blad gen_i18n)")
$enMap = @{}
foreach ($l in (Get-Content -Encoding UTF8 (Join-Path $i18n 'english.tsv'))) {
  $pp = $l -split "`t",2
  if ($pp.Count -ge 2) { $enMap[$pp[1]] = $pp[0] }
}
$plMap = @{}
foreach ($l in (Get-Content -Encoding UTF8 (Join-Path $i18n 'polish.tsv'))) {
  $pp = $l -split "`t",2
  if ($pp.Count -ge 2) { $plMap[$pp[1]] = $pp[0] }
}

foreach ($line in (Get-Content -Encoding UTF8 $pairsFile)) {
  $pp = $line -split "`t",2
  if ($pp.Count -lt 2) { continue }
  $en = $pp[0]; $pl = $pp[1]
  if ($enMap.ContainsKey($en)) { [void]$sb.AppendLine("  KOLIZJA EN: [$en] ID=$($enMap[$en])") }
  else { [void]$sb.AppendLine("  OK EN: [$en]") }
  if ($plMap.ContainsKey($pl)) { [void]$sb.AppendLine("  DUP-PL: [$pl] ID=$($plMap[$pl])") }
}
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Write-Host "Saved: $out"