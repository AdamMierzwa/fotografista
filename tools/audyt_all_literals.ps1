# audyt_all_literals.ps1 - WYSZYSTKIE gole literaly (poza T()) w 7 plikach,
# nieobecne w english.tsv. Wynik -> tools\tmp\audyt_all_literals.txt
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$i18n = Join-Path $root 'i18n'
$tmpd = Join-Path $root 'tools\tmp'
$out = Join-Path $tmpd 'audyt_all_literals.txt'

$known = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($l in (Get-Content -Encoding UTF8 (Join-Path $i18n 'english.tsv'))) {
  $p = $l -split "`t", 2
  if ($p.Count -ge 2) { [void]$known.Add($p[1]) }
}

$files = @('fMain.pas','frmBatchDlg.pas','frmBenchmarkDlg.pas','uImageIO.pas',
           'uRiso.pas','frmShortcutsDlg.pas','frmAmigaBGDlg.pas')

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("AUDYT WSZYSTKICH GOLYCH LITERALOW (poza T()) w 7 plikach")
[void]$sb.AppendLine("Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")

$foundIn = @{}
$all = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($fn in $files) {
  $path = Join-Path $root $fn
  if (-not (Test-Path $path)) { [void]$sb.AppendLine("!! BRAK PLIKU: $fn"); continue }
  $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  $tms = [regex]::Matches($content, "\bT\s*\(\s*'(?:[^']|'')*'")
  $spans = @()
  foreach ($m in $tms) { $spans += [pscustomobject]@{ S = $m.Index; E = $m.Index + $m.Length } }
  $lits = [regex]::Matches($content, "'((?:[^']|'')*)'")
  foreach ($m in $lits) {
    $insideT = $false
    foreach ($sp in $spans) {
      if ($m.Index -ge $sp.S -and $m.Index -lt $sp.E) { $insideT = $true; break }
    }
    if ($insideT) { continue }
    $lit = $m.Groups[1].Value.Replace("''", "'")
    if ($lit -eq '') { continue }
    if ($known.Contains($lit)) { continue }
    if (-not $all.Contains($lit)) {
      [void]$all.Add($lit)
      $foundIn[$lit] = New-Object 'System.Collections.Generic.HashSet[string]'
    }
    [void]$foundIn[$lit].Add($fn)
  }
}
[void]$sb.AppendLine("Unikalnych golych literalow poza T() nieobecnych w TSV: $($all.Count)")
[void]$sb.AppendLine("")
foreach ($s in ($all | Sort-Object)) {
  $fl = ($foundIn[$s] | Sort-Object) -join ', '
  [void]$sb.AppendLine("  [$s]  <- $fl")
}
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Write-Host "Saved: $out"
Write-Host "unique=$($all.Count)"