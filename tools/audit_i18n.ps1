# audit_i18n.ps1 - BRAMKA i18n: katalog <-> konsumenci (.dfm, T() w .pas)
#
# Powod, dla ktorego ten skrypt istnieje: T() przy braku klucza zwraca sam
# angielski litera(l), wiec blad jest cichy - brak wyjatku, brak krachu, brak
# logu. Wlasnie tak przez wiele wydan pozostawalo niezauwazone m.in.
# "Amiga Background" w .dfm wobec klucza "Amiga background". Bramka zamienia
# to w blad kompilacji.
#
# Uzycie:
#   powershell -ExecutionPolicy Bypass -File tools\audit_i18n.ps1
#   powershell -ExecutionPolicy Bypass -File tools\audit_i18n.ps1 -NoDrift
#
# Kody wyjscia: 0 = OK, 1 = blad.
#
# -NoDrift pomija punkt D (zgodnosc uI18n.pas z TSV). gen_i18n.ps1 wywoluje
# bramke z -NoDrift PRZED generowaniem (bo stan niespojny z uI18n.pas jest
# wtedy normalny - wlasnie edytowano TSV), a po generowaniu bez tej flagi.
param([switch]$NoDrift)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$i18n = Join-Path $root 'i18n'
$pas  = Join-Path $root 'uI18n.pas'

# --- Kontrola integralnosci katalogow (modul wspolny z generatorem i audytem) --
# Ulamek BOM/CRLF/formatu ID konczy skrypt kodem 1. Katalog uszkodzony
# kodowaniem nie moze byc uznany za "brak klucza EN" - zglosilby setki bledow
# tresci zamiast jednego, konkretnego bledu pliku.
. (Join-Path $PSScriptRoot 'i18n_common.ps1')
foreach ($L in @('english','polish','czech','french','german','italian','spanish','portuguese','afrikaans')) {
  Assert-TsvIntegrity -Path (Join-Path $i18n ($L + '.tsv'))
}

# ---------------------------------------------------------------------------
# ALLOWLISTA - kazdy wpis musi miec uzasadnienie. Wszystko co tu nie jest
# wymienione, a nie znajduje klucza EN, jest bledem i blokuje build.
# Klucz: "nazwa_pliku|rozwiazana_wartosc" (bez numeru linii - numer przesuwa
# sie przy kazdej edycji wyzej, wartosc nie).
# Uwaga: prefiksy T('...' + liczba) NIE trafiaja tutaj - sprawdza je punkt C
# (wymaga wariantow liczbowych 1-12), wiec np. "Assign ink " jest obsluzony
# automatycznie przez klucze "Assign ink 1".."Assign ink 6".
# ---------------------------------------------------------------------------
$allowDfm = @{
  'frmTshirtDlg.dfm|Islands removed: 0' =
    'podpis budowany runtime: T("Islands removed:") + IntToStr(...)'
}
$allowPas = @{}

# Wzorce wartosci technicznych, ktorych celowo nie tlumaczymy. Trzymane
# wylacznie tutaj, zeby ich nie powiekszac przy kazdym nowym .dfm.
$skipPatterns = @(
  '^[A-Z]:$',                              # etykieta dysku C: / M:
  '^(R|G|B|RGB|WebP|TIFF|JPEG|PNG|BMP|GIF|TIF)$',   # etykiety kanalu / nazwy formatow
  '^R=\d+ G=\d+ B=\d+$',                  # definicje tuszu Risograph
  '\.mp4$',                               # rozszerzenie pliku
  '^[-\+]$',                              # separator w menu
  '^\s+$'                                 # spacje
)

$errors   = New-Object System.Collections.Generic.List[string]
$notes    = New-Object System.Collections.Generic.List[string]
$report   = New-Object System.Text.StringBuilder
function Say($t) { Write-Host $t; [void]$report.AppendLine($t) }

# --- wczytaj english.tsv do zbioru wartosci EN (HashSet = porownanie ordinal,
#     case-sensitive - dokladnie tak, jak dziala slownik w uI18n.pas) ---
$en = New-Object 'System.Collections.Generic.HashSet[string]'
$enByValue = @{}
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $i18n 'english.tsv'), [System.Text.Encoding]::UTF8)) {
  if ($line -eq '') { continue }
  $p = $line -split "`t", 2
  if ($p.Count -eq 2 -and $p[1] -ne '') { [void]$en.Add($p[1]); $enByValue[$p[1]] = $p[0] }
}

# Odwzorowuje zachowanie T() z uI18n.pas: dokladnie, potem obciecie
# koncowego dwukropka, potem dopisanie dwukropka.
function Find-Key([string]$s) {
  if ($en.Contains($s)) { return 'dokladny' }
  if ($s.Length -gt 1 -and $s[$s.Length-1] -eq ':') {
    if ($en.Contains($s.Substring(0, $s.Length-1))) { return 'obciety-koncowy-dwukropek' }
  }
  if ($en.Contains($s + ':')) { return 'dopisany-koncowy-dwukropek' }
  return $null
}

# ---------------------------------------------------------------------------
# A) .dfm - Caption / Text / Hint musi odpowiadac kluczowi EN
#    (z rozwiklaniem konkatenacji 'abc' + #8212 + 'def')
# ---------------------------------------------------------------------------
$dOk = 0; $dSkip = 0
foreach ($f in (Get-ChildItem -LiteralPath $root -Filter '*.dfm' -File)) {
  $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  foreach ($m in [regex]::Matches($c, "(?m)^\s*(Caption|Text|Hint)\s*=\s*((?:'[^']*'|\#\d+)(?:\s*\+?\s*(?:'[^']*'|\#\d+))*)")) {
    $prop = $m.Groups[1].Value
    $sbv  = New-Object System.Text.StringBuilder
    foreach ($t in [regex]::Matches($m.Groups[2].Value, "'([^']*)'|\#(\d+)")) {
      if ($t.Groups[1].Success) { [void]$sbv.Append($t.Groups[1].Value) }
      else { [void]$sbv.Append([char][int]$t.Groups[2].Value) }
    }
    $val = $sbv.ToString()
    if ($val -eq '') { $dSkip++; continue }
    if (Find-Key $val) { $dOk++; continue }

    $lineN = ($c.Substring(0, $m.Index) -split "`n").Count
    $allowKey = "$($f.Name)|$val"
    if ($allowDfm.ContainsKey($allowKey)) { [void]$notes.Add("A) $($f.Name):$lineN allowlista - $($allowDfm[$allowKey])"); continue }
    $skipped = $false
    foreach ($sp in $skipPatterns) { if ($val -match $sp) { $skipped = $true; break } }
    if ($skipped) { $dSkip++; continue }
    if ($val -notmatch '\p{L}') { $dSkip++; continue }

    [void]$errors.Add("A) $($f.Name):$lineN  $prop = [$val]  -> brak klucza EN")
  }
}
Say("A) .dfm Caption/Text/Hint: trafion $dOk, pominieto $dSkip")

# ---------------------------------------------------------------------------
# B) .pas - kazdy literal T('...') musi byc kluczem EN
# ---------------------------------------------------------------------------
$pOk = 0
foreach ($f in (Get-ChildItem -LiteralPath $root -Filter '*.pas' -File)) {
  $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  foreach ($m in [regex]::Matches($c, "\bT\s*\(\s*'((?:[^']|'')*)'\s*\)")) {
    $lit = $m.Groups[1].Value.Replace("''","'")
    if ($lit -eq '') { continue }
    $lineN = ($c.Substring(0, $m.Index) -split "`n").Count
    if (Find-Key $lit) { $pOk++; continue }
    $allowKey = "$($f.Name)|$lit"
    if ($allowPas.ContainsKey($allowKey)) { [void]$notes.Add("B) $($f.Name):$lineN allowlista - $($allowPas[$allowKey])"); continue }
    [void]$errors.Add("B) $($f.Name):$lineN  T('$lit')  -> brak klucza EN")
  }
}
Say("B) .pas T('...'): trafion $pOk")

# ---------------------------------------------------------------------------
# C) .pas - prefiksy T('pref' + ...) musza miec klucz dla konkretnej liczby
# ---------------------------------------------------------------------------
$cOk = 0
foreach ($f in (Get-ChildItem -LiteralPath $root -Filter '*.pas' -File)) {
  $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  foreach ($m in [regex]::Matches($c, "\bT\s*\(\s*'((?:[^']|'')*)'\s*\+")) {
    $lit = $m.Groups[1].Value.Replace("''","'")
    if ($lit -eq '') { continue }
    $lineN = ($c.Substring(0, $m.Index) -split "`n").Count
    $found = $false
    foreach ($d in 1..12) { if (Find-Key ($lit + $d)) { $found = $true; break } }
    if ($found) { $cOk++ } else {
      [void]$errors.Add("C) $($f.Name):$lineN  prefiks T('$lit' + ...) -> brak wariantow liczbowych 1-12")
    }
  }
}
Say("C) .pas prefiksy T('...' + ...): rozpoznane $cOk")

# ---------------------------------------------------------------------------
# D) uI18n.pas <-> TSV (po teskcie EN, nie po pozycji w tablicy)
# ---------------------------------------------------------------------------
if (-not $NoDrift) {
  $txt = [System.IO.File]::ReadAllText($pas, [System.Text.Encoding]::UTF8)
  $inGen = New-Object 'System.Collections.Generic.HashSet[string]'
  $started = $false
  foreach ($ln in ($txt -split "`r`n")) {
    if ($ln -like '*// BEGIN GENERATED TEXTABLE*') { $started = $true; continue }
    if ($ln -like '*// END GENERATED TEXTABLE*')   { $started = $false; continue }
    if (-not $started) { continue }
    $em = [regex]::Match($ln, "EN:\s*'((?:[^']|'')*)'")
    if ($em.Success) { [void]$inGen.Add($em.Groups[1].Value.Replace("''","'")) }
  }
  $missing = @($en | Where-Object { -not $inGen.Contains($_) })
  $orphan  = @($inGen | Where-Object { -not $en.Contains($_) })
  Say("D) uI18n.pas: EN w TSV $($en.Count), w uI18n.pas $($inGen.Count), brak w uI18n $($missing.Count), osierocone $($orphan.Count)")
  foreach ($x in $missing) { [void]$errors.Add("D) EN '$x' jest w english.tsv, ale nie w uI18n.pas - uruchom gen_i18n.ps1") }
  foreach ($x in $orphan)  { [void]$errors.Add("D) EN '$x' jest w uI18n.pas, ale nie w english.tsv") }
}

# ---------------------------------------------------------------------------
# wynik
# ---------------------------------------------------------------------------
foreach ($n in $notes) { Say("   allowlista: $n") }
if ($errors.Count -eq 0) {
  Say("")
  Say("AUDYT i18n: OK - brak niezgodnosci katalog <-> .dfm / .pas")
  $reportDir = Join-Path $root 'tools\tmp'
  if (Test-Path $reportDir) {
    [System.IO.File]::WriteAllText((Join-Path $reportDir 'audit_i18n.txt'), ($report.ToString()), (New-Object System.Text.UTF8Encoding($true)))
  }
  exit 0
}

Say("")
Say("AUDYT i18n: $($errors.Count) bledu/bledow")
foreach ($e in $errors) { Say("  $e") }
Say("")
Say("Popraw .dfm tak, by wartosc byla znak-po-znaku kluczem EN z english.tsv")
Say("(warianty pisowni: spacja, myslnik, wielkosc liter). Jesli wartosc ma byc")
Say("celowo nietlumaczona - dopisz ja do allowlisty w audit_i18n.ps1 z uzasadnieniem.")
$reportDir = Join-Path $root 'tools\tmp'
if (Test-Path $reportDir) {
  [System.IO.File]::WriteAllText((Join-Path $reportDir 'audit_i18n.txt'), ($report.ToString()), (New-Object System.Text.UTF8Encoding($true)))
}
exit 1
