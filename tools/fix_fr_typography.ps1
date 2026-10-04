# fix_fr_typography.ps1 - normalizacja francuskiej typografii w i18n\french.tsv
#
# Wykonuje DOKLADNIE to, czego wymagaja reguly S4d i S4e po korekcie podzialu
# znakow (zrodlo: OQLF, patrz komentarz przy S4e/S4f w audyt_i18n_nietlumaczone.ps1):
#   1) U+202F bezposrednio przed ':'      -> U+00A0   (espace insecable)
#   2) U+202F bezposrednio po '<<' oraz przed '>>' -> U+00A0 (espace insecable)
# Swiadomie NIE rusza:
#   - proporcji "1:1" (tam przed dwukropkiem jest cyfra, nie U+202F)
#   - U+202F przed ';' '?' '!' (tu U+202F jest wlasciwy)
#   - czegokolwiek poza wartoscia (ID, tabulatory)
# Bramka integralnosci jest wymagana przed i po; skrypt konczy sie kodem 1,
# jesli katalog byl uszkodzony PRZED zmiana.

$ErrorActionPreference = 'Stop'
$root = 'C:\Fotografista\Delphi'
. (Join-Path $root 'tools\i18n_common.ps1')

$path = Join-Path $root 'i18n\french.tsv'
Assert-TsvIntegrity -Path $path
Write-Host 'bramka przed zmiana: zaliczona'

$FN = [char]0x202F
$NB = [char]0x00A0
$LQ = [string][char]0x00AB
$RQ = [string][char]0x00BB

# Twarda kontrola: liczba znakow interpunkcyjnych NIE MOZE sie zmienic.
# To jest zabezpieczenie przed powtorka wlasnego bledu - pierwsza wersja tego
# skryptu zgubila 189 dwukropkow, bo zamienila spacje i nie dokleila znaku.
# Gdyby ktokolwiek kiedys edytowal petle w S4, ta kontrola to zatrzyma.
function Count-Char {
  param([string]$v, [string]$ch)
  $n = 0
  for ($i = 0; $i -lt $v.Length; $i++) { if ($v[$i] -eq $ch) { $n++ } }
  return $n
}

$srcLines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
$srcText = [System.IO.File]::ReadAllText($path)
$FN_BEFORE = ([regex]::Matches($srcText, [regex]::Escape([string]$FN))).Count
$colonBefore = 0
foreach ($l in $srcLines) { if ($l -ne '') { $colonBefore += Count-Char ($l -split "`t",2)[1] ':' } }

$lines = $srcLines
$changed = New-Object System.Collections.Generic.List[string]
$out = New-Object System.Collections.Generic.List[string]
$nColon = 0; $nGuil = 0

foreach ($l in $lines) {
  if ($l -eq '') { $out.Add($l); continue }
  $p = $l -split "`t", 2
  if ($p.Count -ne 2) { $out.Add($l); continue }
  $id = $p[0]; $v0 = $p[1]; $v = $v0
  $what = @()

  # 1) U+202F przed dwukropkiem -> U+00A0
  # UWAGA (poprawka wlasnego bledu): pierwsza wersja robila
  #   Remove(ostatni znak); Append(U+00A0)
  # i NIE dokladala samego dwukropka - przez to zjadla 189 znakow ':'.
  # Teraz: zamieniamy spacje I dokladamy znak interpunkcyjny.
  $rebuilt = New-Object System.Text.StringBuilder
  for ($i = 0; $i -lt $v.Length; $i++) {
    $c = $v[$i]
    if ($c -eq ':' -and $i -gt 0 -and $v[$i-1] -eq $FN) {
      [void]$rebuilt.Remove($rebuilt.Length - 1, 1)   # usuwa U+202F
      [void]$rebuilt.Append($NB)                      # wstawia U+00A0
      [void]$rebuilt.Append($c)                       # i ZACHOWUJE dwukropek
      $nColon++
    } else {
      [void]$rebuilt.Append($c)
    }
  }
  $v = $rebuilt.ToString()
  if ($nColon -gt 0) { $what += 'dwukropek' }

  # 2) wnetrze guillemetow (liczone per znak spacji, nie przez dlugosc -
  #    U+202F i U+00A0 to oba znaki jednowymiarowe, wiec roznica dlugosci = 0)
  $before = $v
  $v = $v.Replace($LQ + $FN, $LQ + $NB)
  $v = $v.Replace($FN + $RQ, $NB + $RQ)
  $nGuil += ([regex]::Matches($before, [regex]::Escape($LQ + $FN))).Count
  $nGuil += ([regex]::Matches($before, [regex]::Escape($FN + $RQ))).Count
  if ($v -ne $before) { $what += 'guillemety' }

  if ($v -ne $v0) {
    $changed.Add(("  {0,-5} {1,-12} {2}" -f $id, ($what -join '+'), ($v0 -replace ([regex]::Escape([string]$FN)),'[FN]')))
  }
  $out.Add($id + "`t" + $v)
}

$encb = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllLines($path, $out, $encb)

# weryfikacja po zapisie, z dysku - nie zPamieci
$check = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
$colonAfter = 0; $fnLeft = 0; $nbTotal = 0
$allText = [System.IO.File]::ReadAllText($path)
foreach ($l in $check) { if ($l -ne '') { $colonAfter += Count-Char ($l -split "`t",2)[1] ':' } }
$fnLeft = ([regex]::Matches($allText, [regex]::Escape([string]$FN))).Count
$nbTotal = ([regex]::Matches($allText, [regex]::Escape([string]$NB))).Count

Write-Host ("zmienionych wierszy: {0}   (dwukropki: {1}, znaki w guillemetach: {2})" -f $changed.Count, $nColon, $nGuil)
Write-Host ("  dwukropki  przed={0}  po={1}" -f $colonBefore, $colonAfter)
Write-Host ("  U+202F     przed={0}  po={1}   (po korekcie zostaje 7 przed '?' + 2 przed '!')" -f $FN_BEFORE, $fnLeft)
Write-Host ("  U+00A0     po={0}" -f $nbTotal)
foreach ($c in $changed) { Write-Host $c }

Assert-TsvIntegrity -Path $path
Write-Host 'bramka integralnosci przeszla po zmianie'

if ($colonAfter -ne $colonBefore) {
  Write-Host ("BŁAD KRYTYCZNY: liczba dwukropkow zmienila sie {0} -> {1}. Plik byl uszkodzony - cofnij z git." -f $colonBefore, $colonAfter)
  exit 1
}