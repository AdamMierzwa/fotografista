# audyt_i18n_nietlumaczone.ps1 - raport pozostawionych angielskich wartosci
#
# Bramka audit_i18n.ps1 sprawdza kontrakt "katalog <-> .dfm / T()", czyli czy
# DOPASOWANIE jest dokladne. Nie wyłapie bledu, w ktorym klucz istnieje, a jego
# tresc sama w sobie jest zle (literowka, wielkosc liter, nieprzetlumaczona
# pozycja). Ten skrypt szuka wlasnie tego: jesli dwa klucze dziela ten sam
# "stem" (Risograph v1 / v2... / v3...), a w danym jezyku jeden jest
# przetlumaczony, a drugi nie - to drugi jest prawdopodobnie pominiety.
#
# Uzycie:
#   powershell -ExecutionPolicy Bypass -File tools\audyt_i18n_nietlumaczone.ps1
#
# Znaleziska wartosci (S1-S5, spacje) -> ZAWSZE exit 0. To raport, nie bramka:
# w pelni przetlumaczonych kluczy sa przypadki uzasadnione (zapozyczenia,
# poprawne slowa obce, etykiety techniczne), wiec zablokowanie builda na tym
# etapie byloby wylacznie irytujace. Decyzje o poprawkach zapadaja czytelnie
# raport.
# UŁAMEK INTEGRALNOŚCI TSV -> exit 1 (patrz Test-TsvIntegrity ponizej). Uszkodzone
# kodowanie nie jest kwestia gustu, tylko bledu technicznego.
#
# Raport szczegolowy: tools\tmp\audyt_i18n_nietlumaczone.txt

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $PSScriptRoot
$enc   = [System.Text.Encoding]::UTF8
$encb  = New-Object System.Text.UTF8Encoding($true)
$langs = @('polish','czech','french','german','italian','spanish','portuguese','afrikaans')

# --- Kontrola integralnosci katalogow -----------------------------------------
# Wspolna z tools\gen_i18n.ps1 i tools\audit_i18n.ps1 (modul tools\i18n_common.ps1).
# Ulamek kodowania lub konca pliku konczy skrypt kodem 1. Ciche przejscie
# uszkodzonego TSV jest dokladnie tym, co ta kontrola ma zlapac: podwojny BOM
# przeszedl wczesniejsze bramki, bo sprawdzaly tylko "czy tekst sie daje przegwiazc".
. (Join-Path $PSScriptRoot 'i18n_common.ps1')
foreach ($lg in (@('english') + $langs)) {
  Assert-TsvIntegrity -Path (Join-Path $root "i18n\$lg.tsv")
}

# "stem" = tresc bez numeru wersji i kropek porownana do malych liter.
# Laczy "Risograph v1", "Risograph v2...", "Risograph v3..." w jeden zbior.
function Get-Stem($v) {
  $s = $v.Trim().ToLowerInvariant()
  $s = [regex]::Replace($s, '[\.\u2026]+\s*$', '')
  $s = [regex]::Replace($s, '\s*v?\d+[\.\-a-z]*\s*$', '')
  return $s.Trim()
}

# Zaakceptowane odstepstwa - kazde z uzasadnieniem. Wszystko poza ta lista
# trafia do sekcji "NOWE" i powinno zostac rozwazone.
$known = @{
  '963|czech'      = 'Glitch - zapozyczenie powszechnie uzywane w czeskim'
  '963|french'     = 'Glitch - zapozyczenie powszechnie uzywane'
  '963|spanish'    = 'Glitch - zapozyczenie powszechnie uzywane'
  '963|portuguese' = 'Glitch - zapozyczenie powszechnie uzywane'
  '963|afrikaans'  = 'Glitch - zapozyczenie powszechnie uzywane'
  '933|french'     = 'Relief - poprawne francuskie slowo'
  '933|german'     = 'Relief - poprawne niemieckie slowo'
  '1026|czech'     = 'Stereogram - poprawne zapozyczenie'
  '1026|afrikaans' = 'Stereogram - poprawne zapozyczenie'
  '377|polish'     = 'WB 256 - etykieta techniczna, celowo niezmieniona'
  '497|polish'     = 'Amiga gradient (Agony) - "gradient" jest wspolnym slowem, brak wersji "gradient2"'
  # Francuskie slowa, ktore brzmia identycznie po angielsku - ta sama klasa
  # co 933|french "Relief" i 963|french "Glitch". Dodane 2026-09-29.
  '274|french'     = 'Vignette - identyczne slowo po francusku'
  '396|french'     = 'Duotone - identyczne slowo po francusku'
  '534|french'     = 'Interface - identyczne slowo po francusku'
  '1045|french'    = 'Timelapse - identyczne slowo po francusku'
  '829|french'     = 'Tilt-shift (miniature) - "miniature" jest slowem francuskim'
  '669|french'     = 'ZX Spectrum - nazwa wlasna konsoli'
  '749|french'     = 'NES (Nestopia) - nazwa wlasna emulatora'
  '774|french'     = 'Game Boy - DMG / Pocket - nazwy wlasne sprzetu'
  '793|french'     = 'C64 - Pepto / Colodore - nazwy wlasne emulatorow'
}

# 609 "Emergo" to nazwa wlasna efektu - celowo nieprzetlumaczona we wszystkich
# jezykach, wiec stem-check widzi ja jako "pozostawiona w angielskim" wszedzie.
# Musi zostac wypelnione PRZED petla stem ponizej.
foreach ($L in $langs) {
  $known["609|$L"] = 'Emergo - nazwa wlasna efektu, celowo nieprzetlumaczona'
}

# --- Wyjatki nowych sprawdzen (patrz sekcja "S1/S2/SPACJE" nizej) ---

# S1: tlumaczenie klucza jest znak w znak angielskim zrodlem INNEGO klucza.
# Najczesciej oznaka przesunietego/wklejonego z innego miejsca tekstu.
$knownS1 = @{
  '294|polish'  = 'Halftone = "Raster" - sporny termin, do rozstrzygniecia (patrz CHANGELOG)'
  '394|german'  = 'Emboss = "Relief" - sporny termin, do rozstrzygniecia (patrz CHANGELOG)'
  '753|german'  = 'Emergo = "Glow" - blad, do poprawki po rozstrzygnieciu terminologii'
  '464|italian' = 'Macros = "Macro" - poprawne, wloski rodzaj "macro" jest niezmienny'
  '294|german'  = 'Halftone = "Raster" - sporny termin, tak samo jak 294|polish, do rozstrzygniecia'
}

# --- Reguly wielokropka: S2 i S3 dzialaja WYLACZNIE na forme EN -> tlum. ----
# Zasada (ustalona 2026-09-29): pozycja menu, ktora otwiera okno, ma
# wielokropek. EN jest zrodlem, wiec to on rozstrzyga, ktore klucze go
# niosa, a tlumaczenie ma go powtorzyc. Wiec:
#   S2 - EN konczy wielokropkiem, tlumaczenie nie  -> blad
#   S3 - tlumaczenie konczy wielokropkiem, EN nie  -> blad
# Oba dla KAZDEGO jezyka. To one zastapily dawne S2R/S2X, ktore trzymaly
# 71+12 pozycji jako "klase udokumentowana, swiadomie nietknieta" - to byl
# efekt porownywania z EN, nie opisana konwencja.
# Francuski NIE jest wyjatkiem od tych dwoch (ma te same 9 brakow co wiekszosc
# jezykow). Wyjatkiem typograficznym jest S4, ponizej.
# Pusty $known celowo: brakujace wielokropki to realne bledy do poprawy
# w tlumaczeniach, nie "swiadoma decyzja" - nie trafiaja tutaj.
$knownS2 = @{}
$knownS3 = @{}

# Forma wielokropka NIE jest osobnym regulatem - wynika z konwencji jezyka,
# zmierzonej na katalogach (106x "..." w PL, 102x U+2026 we FR, ~100x "..."
# w pozostalych 6). Dawniej istnial tu wyjatek dla 826/828, bo te dwa rekordy
# mialy U+2026 w 6 jezykach, a "..." wszedzie indziej. To anomalia danych,
# nie regula - znormalizowano te 12 komorek i usunieto wyjatek.

# Spacje: wartosc ma spacje wiodace/koncowe, a angielskie zrodlo jest czyste.
# Klucze 967/988/989 sa wykluczone - tam EN tez ma spacje (wciecia w komunikatach).
$wsSkip = @('967','988','989')

# S4: typografia francuska. FR jest jedynym jezykiem z wlasnymi regulami
# (U+2019 / U+2026 / U+202F / « »). Po normalizacji 2026-09-29 wszystkie 7 regul
# ponizej daje 0 - to detektor regresji, nie lista bladow.
# Swiadomie NIE jest regulowane: U+00A0 przed em-dash (ID 758, 765) -
# dokument francuski tego nie obejmuje, a plik ma to spojnie.
$knownS4 = @{}


$en = Read-TsvChecked (Join-Path $root 'i18n\english.tsv')
$out = New-Object System.Text.StringBuilder
$new = New-Object System.Collections.Generic.List[string]
$old = New-Object System.Collections.Generic.List[string]

foreach ($L in $langs) {
  $t = Read-TsvChecked (Join-Path $root "i18n\$L.tsv")
  $groups = @{}
  foreach ($id in $en.Keys) {
    if (-not $t.ContainsKey($id)) { continue }
    $stem = Get-Stem $en[$id]
    if (-not $groups.ContainsKey($stem)) { $groups[$stem] = New-Object System.Collections.Generic.List[string] }
    $groups[$stem].Add($id)
  }
  $hits = New-Object System.Collections.Generic.List[string]
  foreach ($stem in $groups.Keys) {
    $ids = $groups[$stem]
    if ($ids.Count -lt 2) { continue }
    $diff = 0
    foreach ($id in $ids) { if ($t[$id] -cne $en[$id]) { $diff++ } }
    if ($diff -eq 0 -or $diff -eq $ids.Count) { continue }
    foreach ($id in $ids) {
      if ($t[$id] -ceq $en[$id]) {
        $hits.Add(("{0,-5} {1}='{2}'  {3}='{4}'" -f $id, 'EN', $en[$id], $L, $t[$id]))
      }
    }
  }
  foreach ($h in ($hits | Sort-Object { [int]($_ -split '\s')[0] })) {
    $id = ($h -split '\s')[0]
    $key = "$id|$L"
    if ($known.ContainsKey($key)) { $old.Add("$h   // $($known[$key])") }
    else { $new.Add("$h") }
  }
}

# --- S1 / S2 / SPACJE: bledy tresci, ktorych bramka kontraktowa nie widzi -----
# Wszystkie trzy sa "raportowe" - zero falszywych alarmow gwarantuje to, ze
# kazde trafienie trzeba potwierdzic odczytem pliku, a nie regexem.
$enByValue = @{}
foreach ($id in $en.Keys) { if (-not $enByValue.ContainsKey($en[$id])) { $enByValue[$en[$id]] = $id } }

# 478/479/766 sa spojne w 7 jezykach - jedna decyzja konwencji, nie 21 blad.
foreach ($L in $langs) {
  $knownS2["478|$L"] = 'HAM6 - wielokropek wg spojnej konwencji, swiadoma decyzja'
  $knownS2["479|$L"] = 'HAM8 - wielokropek wg spojnej konwencji, swiadoma decyzja'
  $knownS2["766|$L"] = 'Online documentation - wielokropek wg konwencji dzialu Pomoc'
}

$s1acc = New-Object System.Collections.Generic.List[string]
$s1new = New-Object System.Collections.Generic.List[string]
$s2acc = New-Object System.Collections.Generic.List[string]
$s2new = New-Object System.Collections.Generic.List[string]
$s3acc = New-Object System.Collections.Generic.List[string]
$s3new = New-Object System.Collections.Generic.List[string]
$wsacc = New-Object System.Collections.Generic.List[string]
$wsnew = New-Object System.Collections.Generic.List[string]

foreach ($L in $langs) {
  $t = Read-TsvChecked (Join-Path $root "i18n\$L.tsv")
  foreach ($id in $en.Keys) {
    if (-not $t.ContainsKey($id)) { continue }
    $v = $t[$id]
    $e = $en[$id]
    $key = "$id|$L"

    # S1: tlumaczenie = angielskie zrodlo innego klucza
    if ($enByValue.ContainsKey($v) -and $enByValue[$v] -ne $id) {
      $h = ("{0,-5} EN='{1}'  {2}='{3}'   <- zrodlo EN klucza {4}" -f $id, $e, $L, $v, $enByValue[$v])
      if ($knownS1.ContainsKey($key)) { $s1acc.Add("$h   // $($knownS1[$key])") } else { $s1new.Add($h) }
    }

    # S2: angielskie zrodlo konczy sie wielokropkiem, a tlumaczenie nie ma
    # ZADNEGO wielokropka - brak pozycji menu otwierajacej okno.
    # Sprawdzane sa OBA zapisy ("..." i U+2026), zeby francuski byl
    # mierzony tą samą miarką co pozostale jezyki.
    if ($e -match '(\.\.\.|\u2026)$' -and $v -notmatch '(\.\.\.|\u2026)$') {
      $h = ("{0,-5} EN='{1}'  {2}='{3}'" -f $id, $e, $L, $v)
      if ($knownS2.ContainsKey($key)) { $s2acc.Add("$h   // $($knownS2[$key])") } else { $s2new.Add($h) }
    }

    # S3: tlumaczenie konczy sie wielokropkiem, a angielskie zrodlo nie ma -
    # wielokropek tam, gdzie pozycja menu okna nie otwiera.
    if ($v -match '(\.\.\.|\u2026)$' -and $e -notmatch '(\.\.\.|\u2026)$') {
      $h = ("{0,-5} EN='{1}'  {2}='{3}'" -f $id, $e, $L, $v)
      if ($knownS3.ContainsKey($key)) { $s3acc.Add("$h   // $($knownS3[$key])") } else { $s3new.Add($h) }
    }

    # Spacje wiodace/koncowe, ktorych nie ma w angielskim zrodle
    if ($v -ne $v.Trim() -and $e -ceq $e.Trim() -and $wsSkip -notcontains $id) {
      $h = ("{0,-5} EN='{1}'  {2}='{3}'" -f $id, $e, $L, $v)
      if ($known.ContainsKey($key)) { $wsacc.Add($h) } else { $wsnew.Add($h) }
    }
  }
}

# --- S4: TYPOGRAFIA FRANCUSKA (U+2019 / U+2026 / U+00A0 / U+202F / « ») ------------
# Wyjatek typograficzny, nie obowiazek wobec EN. Francuski ma wlasne reguly
# i jest nimi mierzony TYLKO tutaj - nie wylaczony z S2/S3, bo brakujacych
# wielokropkow ma tyle samo co pozostale jezyki.
# Detektor regresji: po normalizacji 400 komorek (2026-09-29) wszystkie reguly
# daja 0. Zero trafien = katalog jest zgodny z dokumentem typografii.
# Wszystkie wzorce maja guardy: "1:1" (stosunek, ID 121) nie jest dwukropkiem,
# a specyfikatory printf (%s %d %.2f) nie sa znakiem procenta.
$s4acc = New-Object System.Collections.Generic.List[string]
$s4new = New-Object System.Collections.Generic.List[string]
$cAPOS = [char]0x0027; $cELL = [char]0x2026; $cFN = [char]0x202F; $cNB = [char]0x00A0
$cLQ   = [char]0x00AB; $cRQ   = [char]0x00BB
$frTsv = Read-TsvChecked (Join-Path $root 'i18n\french.tsv')
# S4e/S4f: spacje nierozdzielajace przed interpunkcja - DWA znaki, nie jeden.
# Wczesniejsza wersja trzymala : ; ? ! razem pod U+202F. To byl blad dla ':'.
# Zrodlo (OQLF = Office quebecois de la langue franchise, organ rzadowy):
#   vitrinelinguistique.oqlf.gouv.qc.ca/24565 "Types d'espacement":
#     "L'espace inseccable [...] est employe avant ou apres certains signes de
#      ponctuation, comme les chevrons, le deux-points et les guillemets"
#     "L'espace fine est une espace inseccable reduite utilisee devant le point
#      d'interrogation, le point d'exclamation et le point-virgule"
#   /22039 "Espacement avec les signes de ponctuation": "Deux-points : Une espace inseccable"
#   /23325 "Deux-points": "doit etre precede d'une espace inseccable"
# fr.wikipedia "Espace fine inseccable": espace fine tylko przed ; ? !
# U+202F jest wg Unicode "a narrow version of U+00A0" - ten sam podzial.
# Uwaga: kanadyjski fr-CA ma wlasna norme (TERMIUM) i dopuszcza brak spacji
# przed ; ? ! - tu katalog jest europejski francuski, wiec obowiazuje powyzsze.
# Wylaczenie: proporcja "1:1" - cyfra : cyfra to stosunek, nie dwukrojek.
function Test-MissingNoBreak {
  param([string]$v, [string]$Chars, [char]$Req)
  for ($i = 0; $i -lt $v.Length; $i++) {
    $c = [string]$v[$i]
    if ($Chars.IndexOf($c) -lt 0) { continue }
    if ($c -eq ':' -and $i -gt 0 -and ([string]$v[$i-1]) -match '\d' -and ($i+1) -lt $v.Length -and ([string]$v[$i+1]) -match '\d') { continue }
    if ($i -eq 0 -or $v[$i-1] -ne $Req) { return $true }
  }
  return $false
}
# S4f: francuska typografia wymaga, aby znak procentu byl oddzielony od liczby
# nierozdzielajaca spacja U+00A0. Wzorzec lapie 100%, 100 % (zwykla spacja)
# i 100<spacja><spacja>%. Poprawne 100<U+00A0>% nie pasuje, bo U+00A0 jest
# wylaczony z klasy znaku przed procentem.
# Specyfikatory printf (%s, %d, %.2f) sa z definicji bezpieczne: znak % nigdy
# nie stoi bezposrednio po cyfrze, wiec osobny guard nie jest potrzebny
# (sprawdzone na wszystkich 14 specyfikatorach w katalogu francuskim).
$s4Rules = [ordered]@{
  'S4a apostrof prosty U+0027 zamiast typograficznego U+2019' = { param($v) $v.Contains([string]$cAPOS) }
  'S4b trzy kropki zamiast wielokropka U+2026'                = { param($v) $v -match '\.\.\.' }
  'S4c cudzyslow prosty zamiast guillemetow'                   = { param($v) $v.Contains('"') }
  'S4d guillemet bez U+00A0 po stronie wnetrza'                 = { param($v) ($v -match ([regex]::Escape([string]$cLQ) + '(?!' + [regex]::Escape([string]$cNB) + ')')) -or ($v -match ('(?<!' + [regex]::Escape([string]$cNB) + ')' + [regex]::Escape([string]$cRQ))) }
  'S4e dwukropek bez U+00A0 (wylaczenie: proporcja 1:1)'        = { param($v) Test-MissingNoBreak $v ':' ([char]0x00A0) }
  'S4f ; ? ! bez U+202F (espace fine insecable)'                = { param($v) Test-MissingNoBreak $v ';?!' ([char]0x202F) }
  'S4g procent po cyfrze bez U+00A0'                           = { param($v) $v -match '\d[^\u00A0]?%' }
  'S4h U+2026 ze spacja / U+202F na koncu / podwojne U+202F'   = { param($v) $v.Contains(" $cELL") -or $v.EndsWith([string]$cFN) -or $v.StartsWith([string]$cFN) -or $v.Contains("$cFN$cFN") }
}
$s4Count = [ordered]@{}
foreach ($rn in $s4Rules.Keys) { $s4Count[$rn] = 0 }
foreach ($id in @($frTsv.Keys | Sort-Object { [int]$_ })) {
  $val = $frTsv[$id]
  foreach ($rn in $s4Rules.Keys) {
    if (& $s4Rules[$rn] $val) {
      $s4Count[$rn]++
      $h = ("{0,-5} FR='{1}'   <- {2}" -f $id, $val, $rn)
      $key = "$id|french"
      if ($knownS4.ContainsKey($key)) { $s4acc.Add("$h   // $($knownS4[$key])") } else { $s4new.Add($h) }
    }
  }
}

# --- S5: FORMA WIELOKROPKA ZGODNA Z KONWENCJA JEZYKA ---------------------------
# Francuski uzywa U+2026 (jedna kropka "..."), pozostale tlumaczenia trzech
# kropek. Regula S4b pilnuje tego tylko dla francuskiego; S5 pilnuje wszystkich
# katalogow naraz, zeby nie rozjechala sie forma przez przypadkowa edycje
# jednego jezyka.
# Angielski jest zrodlem rozstrzygajacym (kluczem w kodzie jest tekst EN), wiec
# ma wlasnej konwencji nie miec i jest pomijany.
# Swiadomie BEZ tabeli wyjatkow: kazdy rozjazd to realny blad tresci, a nie
# "zaakceptowana decyzja" - to wlasnie przez wpisywanie wszystkiego do $known
# poprzednia wersja reguly przestala cokolwiek wykrywac.
$ellipsisByLang    = @{ 'french' = [string][char]0x2026 }
$defaultEllipsis   = '...'
$ellipsisEndRegex  = '\.\.\.\s*$|[\u2026]\s*$'
$s5acc = New-Object System.Collections.Generic.List[string]
$s5new = New-Object System.Collections.Generic.List[string]
$s5Count = 0
foreach ($lg in $langs) {
  $t5 = Read-TsvChecked (Join-Path $root "i18n\$lg.tsv")
  $want = if ($ellipsisByLang.ContainsKey($lg)) { $ellipsisByLang[$lg] } else { $defaultEllipsis }
  $wantRe = if ($want -eq $defaultEllipsis) { '\.\.\.' } else { [regex]::Escape($want) }
  foreach ($id in @($t5.Keys | Sort-Object { [int]$_ })) {
    $val = $t5[$id]
    if ($val -notmatch $ellipsisEndRegex) { continue }
    if ($val -notmatch ($wantRe + '\s*$')) {
      $s5Count++
      $s5new.Add(("{0,-5} {1}='{2}'   <- koniec nie w konwencji jezyka, oczekiwano '{3}'" -f $id, $lg.ToUpper(), $val, $want))
    }
  }
}

[void]$out.AppendLine('AUDYT WARTOSCI POZOSTAWIONYCH W JEZYKU ANGIELSKIM')
[void]$out.AppendLine('Zrodlo: i18n/*.tsv, grupowanie po "stem" (bez numeru wersji)')
[void]$out.AppendLine('')
[void]$out.AppendLine("=== ZAAKCEPTOWANE ($($old.Count)) ===")
foreach ($o in $old) { [void]$out.AppendLine("  $o") }
[void]$out.AppendLine('')
[void]$out.AppendLine("=== NOWE, DO ROZWAZENIA ($($new.Count)) ===")
if ($new.Count -eq 0) {
  [void]$out.AppendLine('  (brak)')
} else {
  foreach ($n in $new) { [void]$out.AppendLine("  $n") }
}

function Add-Section($title, $acc, $nw) {
  [void]$out.AppendLine('')
  [void]$out.AppendLine("=== $title ===")
  [void]$out.AppendLine("-- ZAAKCEPTOWANE ($($acc.Count)) --")
  if ($acc.Count -eq 0) { [void]$out.AppendLine('  (brak)') } else { foreach ($a in $acc) { [void]$out.AppendLine("  $a") } }
  [void]$out.AppendLine("-- NOWE, DO ROZWAZENIA ($($nw.Count)) --")
  if ($nw.Count -eq 0) { [void]$out.AppendLine('  (brak)') } else { foreach ($a in $nw) { [void]$out.AppendLine("  $a") } }
}

[void]$out.AppendLine('')
[void]$out.AppendLine('AUDYT BLADOW TRESCI (widocznych w UI, niewidocznych dla bramki kontraktowej)')
Add-Section 'S1: TLUMACZENIE = ANGIELSKIE ZRODLO INNEGO KLUCZA' $s1acc $s1new
Add-Section 'S2: WIELOKROPEK W ANGIELSKIM ZRODLE, BRAK W TLUMACZENIU (pozycja menu otwierajaca okno)' $s2acc $s2new
Add-Section 'S3: WIELOKROPEK W TLUMACZENIU, BRAK W ANGIELSKIM ZRODLE' $s3acc $s3new
Add-Section 'S4: TYPOGRAFIA FRANCUSKA - U+2019 / U+2026 / U+202F / guillemety (0 = katalog zgodny)' $s4acc $s4new
Add-Section 'S5: FORMA WIELOKROPKA NIEZGODNA Z KONWENCJA JEZYKA (FR = U+2026, pozostale = trzy kropki)' $s5acc $s5new
Add-Section 'SPACJE WIODACE/KONCOWE, KTORYCH NIE MA W ANGIELSKIM ZRODLE' $wsacc $wsnew

$tmpd = Join-Path $root 'tools\tmp'
if (-not (Test-Path $tmpd)) { New-Item -ItemType Directory -Path $tmpd | Out-Null }
[System.IO.File]::WriteAllText((Join-Path $tmpd 'audyt_i18n_nietlumaczone.txt'), $out.ToString(), $encb)

# Konsola tylko ASCII - raport szczegolowy w pliku (znaki narodowe psuja
# konsole PowerShell 5.1).
Write-Output ("Zaaceptowanych: {0}   Nowych do rozwazenia: {1}" -f $old.Count, $new.Count)
Write-Output ("S1 tresc obcego klucza:  zaakceptowane {0}  nowe {1}" -f $s1acc.Count, $s1new.Count)
Write-Output ("S2 wielokropek bez tlum: zaakceptowane {0}  nowe {1}" -f $s2acc.Count, $s2new.Count)
Write-Output ("S3 wielokropek bez EN:   zaakceptowane {0}  nowe {1}" -f $s3acc.Count, $s3new.Count)
Write-Output ("S4 typografia francuska:   zaakceptowane {0}  nowe {1}" -f $s4acc.Count, $s4new.Count)
Write-Output ("S5 forma wielokropka:        zaakceptowane {0}  nowe {1}" -f $s5acc.Count, $s5new.Count)
foreach ($rn in $s4Rules.Keys) {
  if ($s4Count[$rn] -gt 0) { Write-Output ("   ! {0,-58} {1}" -f $rn, $s4Count[$rn]) }
}
if ($s4new.Count -eq 0) { Write-Output ('   wszystkie {0} regul typografii FR zgodnych (0 naruszen)' -f $s4Rules.Count) }
if ($s5new.Count -eq 0) { Write-Output ('   wszystkie {0} katalogi zgodne z konwencja wielokropka (0 naruszen)' -f $langs.Count) }
Write-Output ("Spacje wiodace/koncowe:  zaakceptowane {0}  nowe {1}" -f $wsacc.Count, $wsnew.Count)
if ($new.Count -gt 0) {
  Write-Output 'Nowe pozycje - szczegoly w tools\tmp\audyt_i18n_nietlumaczone.txt'
}
if ($s2new.Count -gt 0 -or $s3new.Count -gt 0) {
  Write-Output 'S2+S3 to REALNE BLADY w tlumaczeniach (brakujacy lub nadmiarowy wielokropek) - do poprawy, nie do $known.'
}
Write-Output 'Raport: tools\tmp\audyt_i18n_nietlumaczone.txt'
exit 0
