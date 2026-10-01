# audyt_linguistic_qa.ps1 - linguistic QA (typografia), oddzielny od audytu pokrycia
#
# audyt_i18n_nietlumaczone.ps1 sprawdza POKRYCIE (czy klucz ma tlumaczenie) i
# wartosc tresci (S1-S5). Ten skrypt robi inna rzecz: sprawdza KONWENCJE
# TYPOGRAFICZNE jezyka - spacje nierozdzielajace, glify cudzyslowu, forme
# wielokropka. To osobna kompetencja i osobny przebieg swiadomie.
#
# Uzycie:
#   powershell -ExecutionPolicy Bypass -File tools\audyt_linguistic_qa.ps1
#
# Zakres (swiadomie waski - tylko to, czego NIE pilnuje juz S1-S5):
#   L1  wielokropek: obie formy w jednym stringu + wielokropek w srodku zdania
#       (S5 sprawdza tylko KONIEC stringu, wiec te dwa przypadki byly niekryte)
#   L2  hiszpanski: odwrotny znak ? / ! musi byc na poczatku wyrazenia
#   L3a niespojnosc: katalog uzywa glifow cudzyslowu I prostych " naraz
#       (dowodliwe bez tabeli konwencji - sprzecznosc w obrebie jednego katalogu)
#   L3b prosty " w katalogu z deklarowana konwencja typograficzna
#       (tabela $QuoteConvention ponizej - zatwierdzona przez uzytkownika
#        2026-10-01; zweryfikowane glify: patrz komentarze przy wpisach)
#   L4  separatory liczb - CELOWO NIE ZAIMLEMENTOWANE, patrz sekcja L4 nizej
#
# Znaleziska -> exit 0 (to raport, nie bramka). Ulamek integralnosci TSV -> exit 1.
# Raport szczegolowy: tools\tmp\linguistic_qa.txt

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $PSScriptRoot
$enc   = [System.Text.Encoding]::UTF8
$encb  = New-Object System.Text.UTF8Encoding($true)
$langs = @('english','polish','czech','french','german','italian','spanish','portuguese','afrikaans')

# --- Wspolna bramka integralnosci ---------------------------------------------
. (Join-Path $PSScriptRoot 'i18n_common.ps1')
foreach ($lg in $langs) {
  Assert-TsvIntegrity -Path (Join-Path $root "i18n\$lg.tsv")
}

$ELL_UNI   = [string][char]0x2026      # …
$ELL_DOTS  = '...'
$QUOTE_L   = [string][char]0x201E      # „
$QUOTE_R_HI= [string][char]0x201C      # "
$QUOTE_R_LO= [string][char]0x201D      # ”
$GUILL_L   = [string][char]0x00AB      # <<
$GUILL_R   = [string][char]0x00BB      # >>

# L3b: konwencja cudzyslowu na jezyk - ZATWIERDZONA przez uzytkownika 2026-10-01.
# Tabela jest BINARNA: dokladnie jedna poprawna para glifow na jezyk. U+201D
# w katalogu DE/CS to nie "wariant stylistyczny" tylko blad - patrz sekcja
# "Pułapka Unicode" w CHANGELOG.md i komentarz ponizej.
#
# Pułapka Unicode (wątek Unicode Mail List, Otto Stolz, 2006):
# Unicode ZUNIFIKOWAL angielski znak otwierajacy i niemiecki zamykajacy pod
# jeden punkt kodowy U+201C. W angielskim U+201C to "LEFT DOUBLE QUOTATION
# MARK" = otwarcie, ale w niemieckim/czeskim ten sam znak uzywany jest jako
# ZAMKNIECIE. Stąd auto-pary "smart quotes" (bez znajomosci locale) lacza
# „ (U+201E) z U+201D, co jest bledem, nie wariantem. Poprawna para
# dla PL/CS/DE to: U+201E (otwarcie) + U+201C (zamkniecie).
#
# Podzial na trzy rodziny:
#   - PL / CS / DE: „…” (U+201E…U+201C) - low-9 + high-9 (zamkniecie U+201C)
#   - IT / ES / PT: «…» (U+00AB…U+00BB) - konwencja romanska (PT-PT)
#   - AF: "…” (U+201C…U+201D) - konwencja anglo-amerykanska
#     (Wikipedia "Quotation marks": Afrikaans standard = "…", aanhalingsteken)
# Zrodla: Wikipedia "Quotation marks" (summary table), Unicode Mail List 2006.
$QuoteConvention = @{
  'german'     = @{ Open = $QUOTE_L;  Close = $QUOTE_R_HI }  # „…" (U+201E…U+201C)
  'polish'     = @{ Open = $QUOTE_L;  Close = $QUOTE_R_HI }  # „…” (U+201E…U+201C)
  'czech'      = @{ Open = $QUOTE_L;  Close = $QUOTE_R_HI }  # „…” (U+201E…U+201C)
  'italian'    = @{ Open = $GUILL_L;  Close = $GUILL_R }     # «…» (U+00AB…U+00BB)
  'spanish'    = @{ Open = $GUILL_L;  Close = $GUILL_R }     # «…» (U+00AB…U+00BB)
  'portuguese' = @{ Open = $GUILL_L;  Close = $GUILL_R }     # «…» (U+00AB…U+00BB) PT-PT
  # 'afrikaans' celowo pominiete: Afrikaans nasladuje konwencje brytyjska,
  # proste " jest dopuszczalne (decyzja uzytkownika 2026-10-01). Pomiar
  # katalogu: 0 glifow typograficznych, 8 prostych cudzyslowow - dokladnie
  # jak w 'english'. Wylaczenie jest wiec bezstratne: nie ma czego sprawdzac.
  # 'english' celowo pominiete: proste " jest w angielskim dopuszczalny
}

function Vis {
  param([string]$v)
  $s = $v -replace ([regex]::Escape($ELL_UNI)),   '[ELL]'
  $s = $s -replace ([regex]::Escape($ELL_DOTS)),  '[DOT3]'
  $s = $s -replace ([regex]::Escape([string][char]0x202F)),'[FN]'
  $s = $s -replace ([regex]::Escape([string][char]0x00A0)),'[NB]'
  $s = $s -replace ([regex]::Escape([string][char]0x00BF)),'[INQ]'
  $s = $s -replace ([regex]::Escape([string][char]0x00A1)),'[EXC]'
  $s = $s -replace '"',                              '"'
  $s = $s -replace ([regex]::Escape($QUOTE_L)),    '[,,]'
  $s = $s -replace ([regex]::Escape($QUOTE_R_HI)), '[^^]'
  $s = $s -replace ([regex]::Escape($QUOTE_R_LO)), '[^^]'
  $s = $s -replace ([regex]::Escape($GUILL_L)),    '[<<]'
  $s = $s -replace ([regex]::Escape($GUILL_R)),    '[>>]'
  return $s
}

# Prosty cudzyslow dziala jako cytat tylko gdy tworzy pare; cale w calosci
# (np. 5" x 3") nie jest cytatem i musi byc odpuszczone.
function Test-QuotationUse {
  param([string]$v)
  $i = 0
  while ($true) {
    $i = $v.IndexOf('"', $i)
    if ($i -lt 0) { return $false }
    $j = $v.IndexOf('"', $i + 1)
    if ($j -lt 0) { return $false }
    # calkowity cal na obu stronach => para cytatu
    $before = if ($i -gt 0) { $v[$i-1] } else { [char]0 }
    $after  = if ($j+1 -lt $v.Length) { $v[$j+1] } else { [char]0 }
    $leftDigit  = ($before -match '\d')
    $rightDigit = ($after  -match '\d')
    if (-not ($leftDigit -and $rightDigit)) { return $true }
    $i = $j + 1
  }
}

# Odwrotny znak hiszpanski (? / !) jest poprawny na poczatku wyrazenia:
# start stringu, albo po znaku konczacym zdanie z ewentualna spacja.
function Test-InvertedStart {
  param([string]$v, [int]$pos)
  $i = $pos - 1
  while ($i -ge 0 -and ($v[$i] -eq ' ' -or $v[$i] -eq [char]0x00A0 -or $v[$i] -eq [char]0x202F)) { $i-- }
  if ($i -lt 0) { return $true }
  $p = [string]$v[$i]
  return ($p -eq '.' -or $p -eq '!' -or $p -eq '?' -or $p -eq ':' -or $p -eq ';' -or $p -eq [string][char]0x00BF -or $p -eq [string][char]0x00A1)
}

$out = New-Object System.Collections.Generic.List[string]
$acc = New-Object System.Collections.Generic.List[string]
[void]$out.Add('LINGUISTIC QA - KONWENCJE TYPOGRAFICNE (osobne od pokrycia i18n)')
[void]$out.Add('Zrodlo: i18n/*.tsv, bramka integralnosci zaliczona')
[void]$out.Add('')

$cat = [ordered]@{
  'L1a wielokropek: obie formy (...) i (…) w jednym stringu'   = @()
  'L1b wielokropek w srodku zdania (nie koniec), niezgodny z konwencja' = @()
  'L2 hiszpanski: odwrotny ? / ! poza poczatkiem wyrazenia'     = @()
  'L3a niespojnosc katalogu: glify cudzyslowu i proste " naraz' = @()
  'L3b proste " w katalogu z konwencja typograficzna' = @()
  'L3c zly glif zamkniecia cudzyslowu (tabela binarna)' = @()
}

# Wszystkie glify cudzyslowu (prawidlowe i bledne) - wspolna lista zrodlowa dla
# reguly L3c. U+201C bywa OTWARCIEM (AF) i ZAMKNIECIEM (PL/CS/DE) - dlatego
# pozycje rozstrzyga tabela $QuoteConvention, nie nazwa glifu.
$allQuoteGlyphs = @($QUOTE_L,$QUOTE_R_HI,$QUOTE_R_LO,$GUILL_L,$GUILL_R,[string][char]0x0022)

foreach ($lg in $langs) {
  $t = Read-TsvChecked -Path (Join-Path $root "i18n\$lg.tsv")
  $ids = @($t.Keys | Sort-Object { [int]$_ })
  $hasTypographic = $false
  $straightUse = @()

  foreach ($id in $ids) {
    $v = $t[$id]

    # --- L1a: obie formy wielokropka w jednym stringu ---
    if ($v.Contains($ELL_UNI) -and $v.Contains($ELL_DOTS)) {
      $cat['L1a wielokropek: obie formy (...) i (…) w jednym stringu'] += ("  {0,-5} {1}='{2}'" -f $id,$lg.ToUpper(),(Vis $v))
    }

    # --- L1b: wielokropek w srodku, nie na koncu ---
    $want = if ($lg -eq 'french') { $ELL_UNI } else { $ELL_DOTS }
    $core = $v
    $tailOk = $true
    if ($want -eq $ELL_DOTS) { if ($core -match '\.\.\.\s*$') { $tailOk = $true } }
    $mid = if ($want -eq $ELL_DOTS) { ($core -replace '\.\.\.\s*$','') } else { ($core -replace '\u2026\s*$','') }
    $midHas = if ($want -eq $ELL_DOTS) { $mid.Contains($ELL_DOTS) } else { $mid.Contains($ELL_UNI) }
    if ($midHas) {
      $cat['L1b wielokropek w srodku zdania (nie koniec), niezgodny z konwencja'] += ("  {0,-5} {1}='{2}'   oczekiwano konca '{3}'" -f $id,$lg.ToUpper(),(Vis $v),$want)
    }

    # --- L2: hiszpanskie odwrotne znaki ---
    # Wazne: ¿ i ¡ stoją na POCZATKU wyrazenia, niekoniecznie na poczatku
    # stringa - "A. ¿B?" jest poprawne. Dozwolone: start stringu albo po
    # znaku konczacym zdanie (. ! ? :) z ewentualna spacja w miedzy.
    # Pierwsza wersja reguly dopuszczala tylko pozycje 0 i przez to zglosila
    # ID 593 jako blad - to byl falszywy alarm, nie brak katalogu.
    if ($lg -eq 'spanish') {
      if ($v.Length -gt 0) {
        if ($v[0] -eq '?') {
          $cat['L2 hiszpanski: odwrotny ? / ! poza poczatkiem wyrazenia'] += ("  {0,-5} ES='{1}'   poczatek ASCII '?', powinno byc U+00BF" -f $id,(Vis $v))
        }
        if ($v[0] -eq '!') {
          $cat['L2 hiszpanski: odwrotny ? / ! poza poczatkiem wyrazenia'] += ("  {0,-5} ES='{1}'   poczatek ASCII '!', powinno byc U+00A1" -f $id,(Vis $v))
        }
      }
      foreach ($g in @([string][char]0x00BF, [string][char]0x00A1)) {
        $p = $v.IndexOf($g)
        while ($p -ge 0) {
          if (-not (Test-InvertedStart $v $p)) {
            $cat['L2 hiszpanski: odwrotny ? / ! poza poczatkiem wyrazenia'] += ("  {0,-5} ES='{1}'   U+{2:X4} na pozycji {3}, nie na poczatku wyrazenia" -f $id,(Vis $v),[int]$g[0],$p)
          }
          $p = $v.IndexOf($g, $p + 1)
        }
      }
    }

    # --- zbiorek dla L3: jakich glifow uzywa katalog ---
    if ($v.Contains($QUOTE_L) -or $v.Contains($QUOTE_R_HI) -or $v.Contains($QUOTE_R_LO) -or $v.Contains($GUILL_L) -or $v.Contains($GUILL_R)) { $hasTypographic = $true }
    if ((Test-QuotationUse $v)) { $straightUse += $id }
  }

  # --- L3a: katalog ma i glify, i proste " => sprzecznosc, bez tabeli konwencji ---
  if ($hasTypographic -and $straightUse.Count -gt 0) {
    foreach ($id in $straightUse) {
      $cat['L3a niespojnosc katalogu: glify cudzyslowu i proste " naraz'] += ("  {0,-5} {1}='{2}'   katalog uzywa juz glifow typograficznych" -f $id,$lg.ToUpper(),(Vis $t[$id]))
    }
  }

  # --- L3b: konwencja deklarowana dla tego jezyka (BINARNA) ---
  # Wykrywa DWA rodzaje bledu:
  #   1) proste " zamiast deklarowanej pary glifow
  #   2) zly glif ZAMKNIECIA - dla PL/CS/DE U+201D zamiast U+201C (pulapka
  #      Unicode opisana przy $QuoteConvention), dla IT/ES/PT proste " oraz
  #      low-9 „...”, dla AF low-9 „...” zamiast high-9 "..."
  if ($QuoteConvention.ContainsKey($lg)) {
    $c = $QuoteConvention[$lg]

    foreach ($id in $straightUse) {
      $cat['L3b proste " w katalogu z konwencja typograficzna'] += ("  {0,-5} {1}='{2}'   konwencja: {3}...{4}" -f $id,$lg.ToUpper(),(Vis $t[$id]),(Vis $c.Open),(Vis $c.Close))
    }

    # zly glif ZAMKNIECIA - wykrywany POZYCJONIE, nie skanem po stringu.
    # Poprzednia wersja szukala kazdego "obcego" glifu gdziekolwiek w tekscie,
    # przez co poprawny niemiecki „ ... " byl raportowany jako blad (sama
    # para otwarcia byla wzieta za zly glif). Teraz: po kazdym poprawnym
    # OPEN szukamy NASTEPNEGO glifu cudzyslowu - to jest zamkniecie. Jesli
    # nie jest deklarowanym Close, mamy blad.
    $allQuoteGlyphs2 = $allQuoteGlyphs
    foreach ($id in $ids) {
      $v = $t[$id]
      $scan = 0
      while ($true) {
        $o = $v.IndexOf($c.Open, $scan)
        if ($o -lt 0) { break }
        # nastepny glif cudzyslowu po otwarciu = zamkniecie
        $closePos = -1; $closeGlyph = $null
        for ($k = $o + 1; $k -lt $v.Length; $k++) {
          $ch = [string]$v[$k]
          if ($allQuoteGlyphs -contains $ch) { $closePos = $k; $closeGlyph = $ch; break }
        }
        if ($closePos -ge 0 -and $closeGlyph -ne $c.Close) {
          $why = if ($closeGlyph -eq $QUOTE_R_LO -and $c.Close -eq $QUOTE_R_HI) {
            'U+201D zamiast U+201C - pulapka Unicode (U+201C to zamkniecie w tej konwencji)'
          } elseif ($closeGlyph -eq [string][char]0x0022) {
            'proste " zamiast deklarowanego zamkniecia'
          } else {
            "U+{0:X4} zamiast U+{1:X4}" -f [int][char]$closeGlyph,[int][char]$c.Close
          }
          $cat['L3c zly glif zamkniecia cudzyslowu (tabela binarna)'] += ("  {0,-5} {1}='{2}'   {3}" -f $id,$lg.ToUpper(),(Vis $v),$why)
        }
        $scan = $o + 1
      }
    }
  }
}

# --- L4: separatory liczb - POMINIETE CELOWO ---------------------------------
# Pomiar 2026-09 na wszystkich 9 katalogach: kandydaci na liczby z separatorem
# dziesietnym = 1 na katalog (to specyfikatory printf, nie tekst uzytkownika),
# kandydaci na grupowanie = 0. Brak danych => regula byly martwa. Nie pisac
# reguly bez realnego case'a - dokladnie ta zasada zostala przy "700" w
# formule Cell.

foreach ($k in $cat.Keys) {
  $items = @($cat[$k])
  $hdr = $k.ToUpper()
  [void]$out.Add("=== $hdr ===")
  [void]$out.Add("  znalezisk: $($items.Count)")
  foreach ($x in $items) { [void]$out.Add($x) }
  if ($items.Count -eq 0) { [void]$out.Add('  (brak)') }
  [void]$out.Add('')
  if ($items.Count -gt 0) { $acc.Add("$k = $($items.Count)") }
}

[void]$out.Add('=== L4 separatory liczb: REGULA NIEZAIMPLEMENTOWANA (brak danych) ===')
[void]$out.Add('  kandydaci grupowanie = 0, dziesietne = 1/katalog (printf), w 9 katalogach')
[void]$out.Add('')
[void]$out.Add('=== KONWENCJE CUDZYSLOW (tabela binarna, zatwierdzona 2026-10-01) ===')
[void]$out.Add('  PL  „…” (U+201E…U+201C)   CS  „…” (U+201E…U+201C)   DE  „…” (U+201E…U+201C)')
[void]$out.Add('  IT  «…» (U+00AB…U+00BB)   ES  «…» (U+00AB…U+00BB)   PT  «…» (U+00AB…U+00BB, PT-PT)')
[void]$out.Add('  AF  proste " (Afrikaans konwencja brytyjska)   EN  proste " (klucz kontraktu)')
[void]$out.Add('  U+201D w PL/CS/DE = BŁĄD, nie wariant (pułapka Unicode: U+201C to')
[void]$out.Add('  „zamknięcie" w DE/CS mimo nazwy LEFT DOUBLE QUOTATION MARK).')
[void]$out.Add('')
[void]$out.Add("PODSUMOWANIE REGUL Z NARUSZENIAMI: $($acc.Count)")
foreach ($a in $acc) { [void]$out.Add("  $a") }

$repPath = Join-Path $root 'tools\tmp\linguistic_qa.txt'
[System.IO.File]::WriteAllText($repPath, ($out -join "`r`n"), $encb)
Write-Host ("Raport: {0}" -f $repPath)
Write-Host ("Regule z naruszeniami: {0}" -f $acc.Count)
exit 0
