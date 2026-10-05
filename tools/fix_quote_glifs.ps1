# fix_quote_glifs.ps1 - ujednolicenie glifow cudzyslowu do tabeli konwencji
#
# Zakres (potwierdzony przez uzytkownika 2026-10-01):
#   PL, CS, DE  ->  U+201E ... U+201C  („...")
#   IT, ES, PT  ->  U+00AB ... U+00BB  («...»)      PT-PT = europejski
#   AF          ->  NIE RUSZAM (konwencja niepotwierdzona w tym przebiegu)
#   EN          ->  NIE RUSZAM (klucz kontraktu .dfm / T())
#
# WAZNE - pulapka Unicode: w DE/CS U+201C jest ZAMKNIECIEM mimo nazwy
# "LEFT DOUBLE QUOTATION MARK". U+201D to w tych jezykach blad, nie wariant
# (watek Unicode Mail List, Otto Stolz 2006).
#
# Ten skrypt jest JEDNORAZOWY. Po poprawce zostaje w repo jako dokumentacja
# reguly, ale audyt go nie wywoluje - tak jak fix_fr_typography.ps1.
#
# BRAMKI bezpieczenstwa (z glowa z fix_fr_typography.ps1, gdzie pierwsza
# wersja zjedla 189 dwukropkow):
#   1) Assert-TsvIntegrity przed i po
#   2) round-trip: zamiana musi odtwarzac oryginal po podmianie w drugą stronę
#      (jesli nie, algorytm cos zlepil - przerwanie, exit 1)
#   3) liczba dwukropkow ':' NIE MOZE sie zmienic
#   4) raportuje kazda zmieniona komorke - bramka zostaje zamknieta recznie
#
# UWAGA o PowerShell: $STRAIGHT NIE MOZE byc zapisane jako '"' (podwojny
# cudzyslow delimituje string = dwa znaki). Dostęp tylko przez kod punktowy.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'tools\i18n_common.ps1')
$encb = New-Object System.Text.UTF8Encoding($true)

$STRAIGHT = [string][char]0x0022
$QL  = [string][char]0x201E   # "  low-9   (otwarcie PL/CS/DE)
$QR  = [string][char]0x201C   # "  high-9  (zamkniecie PL/CS/DE - pulapka!)
$WR  = [string][char]0x201D   # "  right-9 (bled w PL/CS/DE)
$GL  = [string][char]0x00AB   # << otwarcie IT/ES/PT
$GR  = [string][char]0x00BB   # >> zamkniecie IT/ES/PT

# konwencja per jezyk - TYLKO potwierdzone przez uzytkownika
$convention = @{
  'polish'     = @{ O = $QL; C = $QR }
  'czech'      = @{ O = $QL; C = $QR }
  'german'     = @{ O = $QL; C = $QR }
  'italian'    = @{ O = $GL; C = $GR }
  'spanish'    = @{ O = $GL; C = $GR }
  'portuguese' = @{ O = $GL; C = $GR }
  # afrikaans celowo pominiete - do potwierdzenia przez uzytkownika
  # english celowo pominiete - klucz kontraktu
}

function Count-Char {
  param([string]$v,[string]$ch)
  $n = 0
  for ($i = 0; $i -lt $v.Length; $i++) { if ($v[$i] -eq $ch) { $n++ } }
  return $n
}

# Zwraca indeksy cudzyslowow tworzacych PARE cytatu. Pomija "5" x 3"" -
# cudzyslowy z cyfra po obu stronach to caly, nie cytat.
function Find-QuotePairs {
  param([string]$v)
  $pairs = New-Object System.Collections.Generic.List[object]
  $i = 0
  while ($true) {
    $i = $v.IndexOf($STRAIGHT,$i)
    if ($i -lt 0) { break }
    $j = $v.IndexOf($STRAIGHT,$i + 1)
    if ($j -lt 0) { break }
    $b = if ($i -gt 0) { $v[$i-1] } else { [char]0 }
    $a = if ($j+1 -lt $v.Length) { $v[$j+1] } else { [char]0 }
    if (-not (($b -match '\d') -and ($a -match '\d'))) {
      [void]$pairs.Add(@($i,$j))
    }
    $i = $j + 1
  }
  return $pairs
}

# Podmiana znak po znaku, od prawej do lewej (indeksy pozostaja aktualne).
# NIE używa $parts -join - ta wersja generowala dodatkowe proste cudzyslowy.
function Convert-Quotes {
  param([string]$v,[string]$O,[string]$C)
  $pairs = @(Find-QuotePairs $v)
  if ($pairs.Count -eq 0) { return $v }
  $copy = $v
  for ($k = $pairs.Count - 1; $k -ge 0; $k--) {
    $p = $pairs[$k]
    $copy = $copy.Substring(0,$p[1]) + $C + $copy.Substring($p[1] + 1)
    $copy = $copy.Substring(0,$p[0]) + $O + $copy.Substring($p[0] + 1)
  }
  return $copy
}

function Undo-Quotes {
  param([string]$v,[string]$O,[string]$C)
  return (($v -replace ([regex]::Escape($O)),$STRAIGHT) -replace ([regex]::Escape($C)),$STRAIGHT)
}

$changedAll = New-Object System.Collections.Generic.List[string]
$critical   = 0

foreach ($lg in ($convention.Keys | Sort-Object)) {
  $path = Join-Path $root "i18n\$lg.tsv"
  Assert-TsvIntegrity -Path $path
  $c = $convention[$lg]

  $lines = [System.IO.File]::ReadAllLines($path,[System.Text.Encoding]::UTF8)
  $colonBefore = 0
  foreach ($l in $lines) { if ($l -ne '') { $colonBefore += Count-Char ($l -split "`t",2)[1] ':' } }

  $out = New-Object System.Collections.Generic.List[string]
  $nChanged = 0; $nPairs = 0; $nCloseFix = 0

  foreach ($l in $lines) {
    if ($l -eq '') { $out.Add($l); continue }
    $p = $l -split "`t",2
    if ($p.Count -ne 2) { $out.Add($l); continue }
    $id = $p[0]; $v0 = $p[1]; $v = $v0; $notes = @()

    # 1) proste " jako para -> para glifow konwencji
    $v1 = Convert-Quotes $v $c.O $c.C
    if ($v1 -ne $v) {
      if ((Undo-Quotes $v1 $c.O $c.C) -ne $v0) {
        $critical++
        Write-Host ("KRYTYCZNE {0} {1}: round-trip nie zgadza sie, komorka POMINIETA" -f $lg,$id)
      } else {
        $v = $v1
        $nPairs += @(Find-QuotePairs $v0).Count
        $notes += "para->$($c.O)$($c.C)"
      }
    }

    # 2) zly glif zamkniecia - para „ + U+201D tam gdzie konwencja
    #    wymaga „ + U+201C (pułapka Unicode)
    if ($v.Contains($QL)) {
      $new = $v.Replace($QL + $WR, $QL + $QR)
      if ($new -ne $v) {
        $nCloseFix += ([regex]::Matches($v,[regex]::Escape($QL + $WR))).Count
        $v = $new
        $notes += 'zamkniecie U+201D->U+201C'
      }
    }

    if ($v -ne $v0) {
      $nChanged++
      [void]$changedAll.Add(("{0,-11} {1,-5} {2}" -f $lg,$id,($notes -join '; ')))
    }
    $out.Add($id + "`t" + $v)
  }

  if ($nChanged -gt 0) { [System.IO.File]::WriteAllLines($path,$out,$encb) }

  # weryfikacja z dysku
  $check = [System.IO.File]::ReadAllLines($path,[System.Text.Encoding]::UTF8)
  $colonAfter = 0
  foreach ($l in $check) { if ($l -ne '') { $colonAfter += Count-Char ($l -split "`t",2)[1] ':' } }

  Write-Host ("{0,-11} komorek zmienionych: {1,3}  (pary prosty->glify: {2}, zamkniecie U+201D->U+201C: {3})" -f $lg,$nChanged,$nPairs,$nCloseFix)
  Write-Host ("             dwukropki przed: {0}  po: {1}  {2}" -f $colonBefore,$colonAfter,$(if ($colonAfter -eq $colonBefore) { 'OK' } else { 'BLAD KRYTYCZNY' }))
  Assert-TsvIntegrity -Path $path
  Write-Host '             bramka integralnosci: zaliczona'
  if ($colonAfter -ne $colonBefore) { $critical++ }
}

Write-Host ''
Write-Host ("lacznie komorek zmienionych: {0}   krytycznych: {1}" -f $changedAll.Count,$critical)
foreach ($c in $changedAll) { Write-Host "  $c" }
Write-Host ''
Write-Host 'AF i EN celowo nieobjete - AF do potwierdzenia, EN to klucz kontraktu.'
if ($critical -gt 0) { exit 1 }