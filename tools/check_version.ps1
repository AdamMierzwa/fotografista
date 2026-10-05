# check_version.ps1 - krzyzowe sprawdzenie numeru wersji (ASCII only).
# Porownuje 4 zrodla, z ktorych tylko pierwsze trafia do EXE:
#   1. Fotografista.dproj, PropertyGroup "Cfg_1_Win64" (Release -> Cfg_1 -> Cfg_1_Win64)
#      -> VerInfo_Keys / FileVersion + ProductVersion  (REFERENCJA)
#   2. AboutBoxUnit.pas            -> RealAppVersion      (3 skladowe, wyswietlane w UI)
#   3. packaging\x64\AppxManifest.xml -> Identity/@Version (to widzi Microsoft Store)
#   4. tools\build_msix.cmd        -> set VER=            (nazwa pliku paczki)
# Brak pliku oznacza "pominieto", nie blad - packaging\ jest gitignorowany,
# wiec czysty clone nadal musi umiec zbudowac paczke ZIP.
# Wyjscie: 0 = zgodne, 1 = rozjazd (blok) lub nieczytelna referencja.
# Uzycie: powershell -ExecutionPolicy Bypass -File tools\check_version.ps1 [-Root <dir>]
param([string]$Root)

$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }

$outDir = Join-Path $Root 'tools\tmp'
$out = Join-Path $outDir 'check_version.txt'

function Get-SrcLines([string]$rel) {
    $p = Join-Path $Root $rel
    if (-not (Test-Path $p)) { return $null }
    return [System.IO.File]::ReadAllLines($p, [System.Text.Encoding]::UTF8)
}

# Zwraca indeks wiersza ORAZ wartosc grupy 1. Nie mozna tu zwrocic sam $matches:
# $matches jest lokalny dla funkcji, a caller dostalby stara wartosc.
function Get-FirstMatch([string[]]$lines, [string]$pattern) {
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match $pattern) {
            $v = ''
            if ($matches.Count -ge 2) { $v = $matches[1] }
            return [pscustomobject]@{ Index = $i; Value = $v }
        }
    }
    return $null
}

# 3 skladowe ("1.1.1") -> 4 skladowe ("1.1.1.0"); wiecej niz 4 to blad danych
function Convert-ToQuad([string]$v) {
    $parts = @($v -split '\.')
    if ($parts.Count -eq 0 -or $parts.Count -gt 4) { return $null }
    while ($parts.Count -lt 4) { $parts += '0' }
    return ($parts -join '.')
}

$sb = New-Object System.Text.StringBuilder
function Say([string]$s) { [void]$sb.AppendLine($s); Write-Host $s }

Say("=== Sprawdzenie wersji: $Root ===")
Say("(czas: $(Get-Date -Format 'yyyy-MM-dd HH:mm'))")

$sources = @()

# ---- 1. dproj: Win64|Release -> VerInfo_Keys (referencja) ----
$dprojRel = 'Fotografista.dproj'
$lines = Get-SrcLines $dprojRel
if ($null -eq $lines) {
    Say("[BLAD] Brak $dprojRel - nie mam czego sprawdzic.")
    exit 1
}
# Cfg_1_Win64 wystepuje w dwoch PropertyGroup (definicja platformy i sekcja
# VerInfo) - bierzemy ten, ktory faktycznie zawiera VerInfo_Keys, i wymagamy
# dokladnie jednego kandydata.
$cands = @()
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -notmatch 'PropertyGroup' -or $lines[$i] -notmatch 'Cfg_1_Win64') { continue }
    for ($j = $i; $j -lt $lines.Length; $j++) {
        if ($lines[$j] -match '</PropertyGroup>') { break }
        if ($lines[$j] -match 'VerInfo_Keys') { $cands += $j; break }
    }
}
if ($cands.Count -eq 0) {
    Say("[BLAD] W ${dprojRel} nie znaleziono sekcji Win64|Release z VerInfo_Keys.")
    Say("       Referencja to PropertyGroup z warunkiem na Cfg_1_Win64 (Release -> Cfg_1 -> Cfg_1_Win64).")
    Say("       Wzorzec mogl sie zmienic - popraw skrypt, nie zgaduj.")
    exit 1
}
if ($cands.Count -gt 1) {
    Say("[BLAD] W ${dprojRel} jest $($cands.Count) sekcji Win64|Release z VerInfo_Keys (linie $($cands -join ', ')).")
    Say("       Nie wiadomo ktora jest referencja - popraw skrypt, nie zgaduj.")
    exit 1
}
$keysLine = $cands[0]
if ($lines[$keysLine] -notmatch 'FileVersion=([\d.]+)') {
    Say("[BLAD] W ${dprojRel} (wiersz $($keysLine + 1)) brak FileVersion.")
    exit 1
}
$fv = $matches[1]
$refQuad = Convert-ToQuad $fv
if (-not $refQuad) {
    Say("[BLAD] ${dprojRel}: FileVersion='$fv' nie jest numerem wersji.")
    exit 1
}
# ProductVersion to druga polowa tej samej linijki i jest widoczna w Explorerze
# (Wlasciwosci pliku -> Szczegoly -> Wersja). Rozdzaj "Plik 1.1.1.0 / Produkt
# 1.0.6.0" przeszedlby wylacznie na samym FileVersion, wiec trzeba sprawdzic obie.
if ($lines[$keysLine] -notmatch 'ProductVersion=([\d.]+)') {
    Say("[BLAD] W ${dprojRel} (wiersz $($keysLine + 1)) brak ProductVersion.")
    Say("       Referencja musi byc kompletna - inaczej straznik przepuscilby")
    Say("       EXE z dwiema roznymi numerami w obiekcie wersji.")
    exit 1
}
$pv = $matches[1]
$pvQuad = Convert-ToQuad $pv
if (-not $pvQuad) {
    Say("[BLAD] ${dprojRel}: ProductVersion='$pv' nie jest numerem wersji.")
    exit 1
}
if ($pvQuad -ne $refQuad) {
    Say("[BLAD] ${dprojRel}:$($keysLine + 1) FileVersion i ProductVersion sie roznia.")
    Say("       FileVersion=$fv  ProductVersion=$pv")
    Say("       Obie wartosci trafiaja do EXE i obie widzi uzytkownik we")
    Say("       Wlasciwosciach pliku. Ustaw obie na jedna.")
    exit 1
}
$sources += [pscustomobject]@{ Ord = 1; Rel = $dprojRel; Line = $keysLine + 1
    Quad = $refQuad; Fmt = 4; What = 'Win64|Release VerInfo_Keys (REFERENCJA)'
    Short = "FileVersion=$fv, ProductVersion=$pv" }

# ---- 2. AboutBoxUnit.pas: RealAppVersion ----
$aboutRel = 'AboutBoxUnit.pas'
$lines = Get-SrcLines $aboutRel
if ($null -ne $lines) {
    $m = Get-FirstMatch $lines "RealAppVersion\s*=\s*'(\d[\d.]*)'"
    if ($null -eq $m -or $m.Value -eq '') {
        Say("[BLAD] W ${aboutRel} nie znaleziono RealAppVersion.")
        exit 1
    }
    $q = Convert-ToQuad $m.Value
    if (-not $q) {
        Say("[BLAD] ${aboutRel}: RealAppVersion='$($m.Value)' nie jest numerem wersji.")
        exit 1
    }
    $sources += [pscustomobject]@{ Ord = 2; Rel = $aboutRel; Line = $m.Index + 1
        Quad = $q; Fmt = 3; What = 'RealAppVersion (widoczne w O programie)'
        Short = "RealAppVersion = '$($m.Value)'" }
}

# ---- 3. packaging\x64\AppxManifest.xml: Identity/@Version ----
$manifestRel = 'packaging\x64\AppxManifest.xml'
$lines = Get-SrcLines $manifestRel
if ($null -ne $lines) {
    $m = Get-FirstMatch $lines '<Identity\b[^>]*\bVersion="([\d.]+)"'
    if ($null -eq $m -or $m.Value -eq '') {
        Say("[BLAD] W ${manifestRel} brak atrybutu Version w <Identity>.")
        exit 1
    }
    $q = Convert-ToQuad $m.Value
    if (-not $q) {
        Say("[BLAD] ${manifestRel}: Version='$($m.Value)' nie jest numerem wersji.")
        exit 1
    }
    $sources += [pscustomobject]@{ Ord = 3; Rel = $manifestRel; Line = $m.Index + 1
        Quad = $q; Fmt = 4; What = 'Identity/@Version (to widzi Microsoft Store)'
        Short = "Version=`"$($m.Value)`"" }
}

# ---- 4. tools\build_msix.cmd: set VER= ----
$msixRel = 'tools\build_msix.cmd'
$lines = Get-SrcLines $msixRel
if ($null -ne $lines) {
    $m = Get-FirstMatch $lines '^\s*set\s+VER=([\d.]+)'
    if ($null -eq $m -or $m.Value -eq '') {
        Say("[BLAD] W ${msixRel} nie znaleziono 'set VER='.")
        exit 1
    }
    $q = Convert-ToQuad $m.Value
    if (-not $q) {
        Say("[BLAD] ${msixRel}: VER='$($m.Value)' nie jest numerem wersji.")
        exit 1
    }
    $sources += [pscustomobject]@{ Ord = 4; Rel = $msixRel; Line = $m.Index + 1
        Quad = $q; Fmt = 4; What = 'set VER (nazwa pliku MSIX)'
        Short = "set VER=$($m.Value)" }
}

Say("")
$compared = 0
$bad = @()
foreach ($s in ($sources | Sort-Object Ord)) {
    if ($s.Ord -eq 1) {
        Say(("  [REFERENCJA] {0,-10} {1}:{2}  ({3})" -f $s.Quad, $s.Rel, $s.Line, $s.What))
        Say(("                 {0}" -f $s.Short))
        continue
    }
    $compared++
    if ($s.Quad -eq $refQuad) {
        Say(("  [ZGODNE]      {0,-10} {1}:{2}  ({3})" -f $s.Quad, $s.Rel, $s.Line, $s.What))
    } else {
        $bad += $s
        Say(("  [ROZJEZD]     {0,-10} {1}:{2}  ({3})" -f $s.Quad, $s.Rel, $s.Line, $s.What))
    }
}

Say("")
if ($compared -eq 0) {
    Say("Pominieto wszystkie zrodla porownywane z dproj - za malo danych, nie blokuje.")
    Say("Rezystr jest: $refQuad (z $dprojRel)")
    exit 0
}

if ($bad.Count -eq 0) {
    Say("OK - wszystkie wykorzystane zrodla zgodne z ${dprojRel}: $refQuad")
    exit 0
}

Say("ROZJAZD WERSJI - popraw pliki ponizej, potem buduj ponownie.")
Say("Referencja (trafia do EXE): $refQuad z ${dprojRel}:$($sources[0].Line)")
Say("")
foreach ($s in $bad) {
    $parts = @($s.Quad -split '\.')
    if ($s.Fmt -eq 3) { $want = ($parts[0..2] -join '.') } else { $want = $s.Quad }
    Say(("  {0}:{1}  {2}" -f $s.Rel, $s.Line, $s.What))
    Say(("      jest:  {0}   ->  ma byc: {1}" -f $s.Short, $want))
}

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Say("")
Say("Raport: $out")
exit 1
