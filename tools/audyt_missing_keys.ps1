# audyt_missing_keys.ps1 - liczy WYSZYSTKIE gole segmenty literałow w wywołaniach
# MessageDlg, InputQuery, FinishEffect, Lines.Add, Title :=
# w 7 plikach. Wyklucza segmenty wewnątrz T(...). Wynik -> tools\tmp\
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$i18n = Join-Path $root 'i18n'
$tmpd = Join-Path $root 'tools\tmp'
$out = Join-Path $tmpd 'audyt_missing_keys.txt'

$known = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($l in (Get-Content -Encoding UTF8 (Join-Path $i18n 'english.tsv'))) {
  $p = $l -split "`t", 2
  if ($p.Count -ge 2) { [void]$known.Add($p[1]) }
}

$files = @('fMain.pas','frmBatchDlg.pas','frmBenchmarkDlg.pas','uImageIO.pas',
           'uRiso.pas','frmShortcutsDlg.pas','frmAmigaBGDlg.pas')

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("AUDYT GOLYCH LITERALOW (segmenty) vs english.tsv")
[void]$sb.AppendLine("Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("Pliki: $($files -join ', ')")

# segmenty T(...) do wykluczenia
$tSpans = New-Object 'System.Collections.Generic.List[object]'
$missing = New-Object 'System.Collections.Generic.HashSet[string]'
$present = New-Object 'System.Collections.Generic.HashSet[string]'
$foundIn = @{}
$totalSegments = 0

foreach ($fn in $files) {
  $path = Join-Path $root $fn
  if (-not (Test-Path $path)) { [void]$sb.AppendLine("!! BRAK PLIKU: $fn"); continue }
  $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

  # wszystkie wystąpienia T('...') z zakresami
  $tms = [regex]::Matches($content, "\bT\s*\(\s*'(?:[^']|'')*'")
  $spans = @()
  foreach ($m in $tms) { $spans += [pscustomobject]@{ S = $m.Index; E = $m.Index + $m.Length } }

  # konteksty: znajdź pozycje słów kluczowych wywołań
  $kw = 'MessageDlg|InputQuery|FinishEffect|Lines\.Add'
  $kms = [regex]::Matches($content, "\b($kw)\s*\(")
  foreach ($km in $kms) {
    # od słowa kluczowego, poszukaj gołych segmentów literałów do końca linii/wywołania
    $segStart = $km.Index + $km.Length
    $segEnd = $content.IndexOf(');', $segStart)
    if ($segEnd -lt 0) { $segEnd = [Math]::Min($content.Length, $segStart + 300) }
    $region = $content.Substring($segStart, $segEnd - $segStart)
    $segments = [regex]::Matches($region, "'((?:[^']|'')*)'")
    foreach ($seg in $segments) {
      $absPos = $segStart + $seg.Index
      # czy segment leży wewnątrz T(...)?
      $insideT = $false
      foreach ($sp in $spans) {
        if ($absPos -ge $sp.S -and $absPos -lt $sp.E) { $insideT = $true; break }
      }
      if ($insideT) { continue }
      $lit = $seg.Groups[1].Value.Replace("''", "'")
      if ($lit -eq '') { continue }
      $totalSegments++
      if (-not $known.Contains($lit)) {
        if ($missing.Add($lit)) {
          $foundIn[$lit] = New-Object 'System.Collections.Generic.List[string]'
        }
        [void]$foundIn[$lit].Add($fn)
      } else {
        [void]$present.Add($lit)
      }
    }
  }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Segmentów gołych (poza T()): $totalSegments")
[void]$sb.AppendLine("MISSING (nie ma w english.tsv): $($missing.Count)")
[void]$sb.AppendLine("PRESENT: $($present.Count)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("--- MISSING LIST ---")
foreach ($s in ($missing | Sort-Object)) {
  $fl = ($foundIn[$s] | Sort-Object -Unique) -join ', '
  [void]$sb.AppendLine("  [$s]  <- $fl")
}
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Write-Host "Saved: $out"
Write-Host "segments=$totalSegments missing=$($missing.Count) present=$($present.Count)"