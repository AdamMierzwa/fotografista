# audyt_missing_keys_all.ps1 - gole literaly w kontekstach
# MessageDlg, InputQuery, FinishEffect, Lines.Add, Title :=
# we WSZYSTKICH .pas w Delphi (opcjonalnie z wylaczeniem bibliotek).
# Wynik -> tools\tmp\audyt_missing_keys_all.txt
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$i18n = Join-Path $root 'i18n'
$tmpd = Join-Path $root 'tools\tmp'
$out = Join-Path $tmpd 'audyt_missing_keys_all.txt'

$exclude = @('fpdf.pas','bluenoise.pas','uI18n.pas')

$known = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($l in (Get-Content -Encoding UTF8 (Join-Path $i18n 'english.tsv'))) {
  $p = $l -split "`t", 2
  if ($p.Count -ge 2) { [void]$known.Add($p[1]) }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("AUDYT GOLYCH LITERALOW (konteksty: MessageDlg/InputQuery/FinishEffect/Lines.Add/Title := )")
[void]$sb.AppendLine("Zakres: wszystkie .pas, wykluczone: $($exclude -join ', ')")
[void]$sb.AppendLine("Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")

$missing = New-Object 'System.Collections.Generic.HashSet[string]'
$foundIn = @{}
$totalSegments = 0

$files = Get-ChildItem -Path $root -Filter *.pas | Where-Object { $_.Name -notin $exclude } | Sort-Object Name

foreach ($fi in $files) {
  $fn = $fi.Name
  $content = [System.IO.File]::ReadAllText($fi.FullName, [System.Text.Encoding]::UTF8)

  # zakresy T(...)
  $tms = [regex]::Matches($content, "\bT\s*\(\s*'(?:[^']|'')*'")
  $spans = @()
  foreach ($m in $tms) { $spans += [pscustomobject]@{ S = $m.Index; E = $m.Index + $m.Length } }

  $kw = 'MessageDlg|InputQuery|FinishEffect|Lines\.Add'
  $kms = [regex]::Matches($content, "\b($kw)\s*\(")
  foreach ($km in $kms) {
    $segStart = $km.Index + $km.Length
    $segEnd = $content.IndexOf(');', $segStart)
    if ($segEnd -lt 0) { $segEnd = [Math]::Min($content.Length, $segStart + 300) }
    $region = $content.Substring($segStart, $segEnd - $segStart)
    $segments = [regex]::Matches($region, "'((?:[^']|'')*)'")
    foreach ($seg in $segments) {
      $absPos = $segStart + $seg.Index
      $insideT = $false
      foreach ($sp in $spans) {
        if ($absPos -ge $sp.S -and $absPos -lt $sp.E) { $insideT = $true; break }
      }
      if ($insideT) { continue }
      $lit = $seg.Groups[1].Value.Replace("''", "'")
      if ($lit -eq '') { continue }
      $totalSegments++
      if (-not $known.Contains($lit)) {
        if ($missing.Add($lit)) { $foundIn[$lit] = New-Object 'System.Collections.Generic.List[string]' }
        [void]$foundIn[$lit].Add($fn)
      }
    }
  }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Segmentow golych (poza T()): $totalSegments")
[void]$sb.AppendLine("MISSING (nie ma w english.tsv): $($missing.Count)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("--- MISSING LIST ---")
foreach ($s in ($missing | Sort-Object)) {
  $fl = ($foundIn[$s] | Sort-Object -Unique) -join ', '
  [void]$sb.AppendLine("  [$s]  <- $fl")
}
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Write-Host "Saved: $out"
Write-Host "segments=$totalSegments missing=$($missing.Count) files=$($files.Count)"