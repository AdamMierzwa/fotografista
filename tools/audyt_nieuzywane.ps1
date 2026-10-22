# audyt_nieuzywane.ps1 - procedury i funkcje z sekcji interface, ktorych nikt nie wywoluje.
#
# Po co: TshirtReplaceColors (uTshirt.pas) byla przeniesiona, ale nigdzie nie wolana -
# zgubiony krok sprawil, ze Tworzenie nadruku dzielilo obraz farbami zamiast palety
# (naprawione 2026-10-20). Zero wywolan = martwy kod albo zgubiony krok.
#
# Zakres: sledzone przez git pliki *.pas w katalogu projektu (bez Lib\ i podkatalogow)
# + Fotografista.dpr + *.dfm (zdarzenia). Tylko procedury/funkcje na poziomie unitu
# (kolumna 0 w interface); metody klas pominiete (wolane z .dfm i przez VCL).
# Odwolanie = wystapienie nazwy jako calego slowa (bez rozroznienia wielkosci liter)
# poza komentarzami i literalami, z pominieciem linii z deklaracja i naglowkiem
# implementacji tej nazwy w jej unicie.
#
# Wynik: tools\tmp\audyt_nieuzywane.txt (UTF-8 BOM). Uzycie:
#   powershell -ExecutionPolicy Bypass -File tools\audyt_nieuzywane.ps1
# Ten plik jest UTF-8 z BOM, koniec linii LF (jak pozostale .ps1 w tools\).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$pasFiles = @(git ls-files '*.pas' | Where-Object { $_ -notmatch '/' })
$otherFiles = @('Fotografista.dpr') + @(git ls-files '*.dfm' | Where-Object { $_ -notmatch '/' })

function Strip-Code([string]$s) {
  # komentarze { }, (* *), // oraz literaly '...' -> spacje (zachowane konce linii)
  $s = [regex]::Replace($s, "\{[^}]*\}", { param($m) ($m.Value -replace '[^\n]', ' ') })
  $s = [regex]::Replace($s, "\(\*.*?\*\)", { param($m) ($m.Value -replace '[^\n]', ' ') }, 'Singleline')
  $s = [regex]::Replace($s, "//[^\n]*", '')
  $s = [regex]::Replace($s, "'[^'\n]*'", "''")
  return $s
}

$texts = @{}
foreach ($f in $pasFiles + $otherFiles) {
  $raw = [System.IO.File]::ReadAllText((Join-Path $root $f))
  if ($f -like '*.dfm') { $texts[$f] = $raw } else { $texts[$f] = Strip-Code $raw }
}

# 1. deklaracje z interface
$decls = New-Object System.Collections.Generic.List[object]
foreach ($f in $pasFiles) {
  $t = $texts[$f]
  $mI = [regex]::Match($t, '(?im)^\s*interface\b')
  $mM = [regex]::Match($t, '(?im)^\s*implementation\b')
  if (-not $mI.Success -or -not $mM.Success) { continue }
  $intf = $t.Substring($mI.Index, $mM.Index - $mI.Index)
  foreach ($m in [regex]::Matches($intf, '(?im)^(procedure|function)\s+([A-Za-z_][A-Za-z0-9_]*)\b')) {
    $decls.Add([pscustomobject]@{ Unit = $f; Kind = $m.Groups[1].Value; Name = $m.Groups[2].Value })
  }
}

# 2. odwolania
$rows = New-Object System.Collections.Generic.List[object]
$seen = @{}
foreach ($d in $decls) {
  $key = ($d.Unit + '|' + $d.Name).ToLower()
  if ($seen.ContainsKey($key)) { continue }   # przeciazenia - jeden wpis
  $seen[$key] = $true
  $name = [regex]::Escape($d.Name)
  $own = 0; $foreign = 0; $where = New-Object System.Collections.Generic.List[string]
  foreach ($f in $texts.Keys) {
    $lines = $texts[$f] -split "`n"
    $cnt = 0
    foreach ($ln in $lines) {
      if ($f -eq $d.Unit -and $ln -match ('(?i)^\s*(class\s+)?(procedure|function)\s+(\w+\.)?' + $name + '\b')) { continue }
      $cnt += [regex]::Matches($ln, '(?i)(?<![\w.])' + $name + '\b').Count
    }
    if ($cnt -gt 0) {
      if ($f -eq $d.Unit) { $own += $cnt } else { $foreign += $cnt; $where.Add($f) }
    }
  }
  $rows.Add([pscustomobject]@{ Unit = $d.Unit; Name = $d.Name; Own = $own; Foreign = $foreign; Where = ($where -join ', ') })
}

$unused = @($rows | Where-Object { $_.Own -eq 0 -and $_.Foreign -eq 0 } | Sort-Object Unit, Name)
$localOnly = @($rows | Where-Object { $_.Own -gt 0 -and $_.Foreign -eq 0 } | Sort-Object Unit, Name)

$out = New-Object System.Text.StringBuilder
[void]$out.AppendLine('AUDYT NIEUZYWANYCH FUNKCJI (interface) - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
[void]$out.AppendLine(('Unity: {0}, deklaracje: {1}' -f $pasFiles.Count, $rows.Count))
[void]$out.AppendLine('')
[void]$out.AppendLine(('A) ZERO ODWOLAN ({0}) - martwy kod albo zgubiony krok:' -f $unused.Count))
foreach ($r in $unused) { [void]$out.AppendLine(('   {0,-28} {1}' -f $r.Unit, $r.Name)) }
[void]$out.AppendLine('')
[void]$out.AppendLine(('B) TYLKO WE WLASNYM UNICIE ({0}) - uzywane, ale niepotrzebnie w interface (informacyjnie):' -f $localOnly.Count))
foreach ($r in $localOnly) { [void]$out.AppendLine(('   {0,-28} {1}  ({2}x)' -f $r.Unit, $r.Name, $r.Own)) }

$dst = Join-Path $root 'tools\tmp\audyt_nieuzywane.txt'
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($dst, $out.ToString(), $utf8bom)
Write-Output ('Zapisano: ' + $dst + ('  (A: {0}, B: {1})' -f $unused.Count, $localOnly.Count))
