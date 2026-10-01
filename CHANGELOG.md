# Changelog — Fotografista (wersja Delphi)

## [Następna wersja]

Różnica względem wersji sklepowej z 08-09.2026. Elementy już opisane w tej
sekcji — pędzle malowania, klonu, jasności i ostrości, siła per rodzina,
limit skoku dodge/burn, pędzel zamiany koloru, balans bieli, maska ochronna,
zaznaczenia, usuwanie tła — nie są powtarzane. Poniżej tylko to, co doszło
lub zmieniło zachowanie.

### Added

**Wspólna bramka integralności katalogów** (`tools/i18n_common.ps1`,
`tools/i18n_common_test.ps1`) — moduł używany przez wszystkie trzy skrypty i18n
(`gen_i18n`, `audit_i18n`, `audyt_i18n_nietlumaczone`). Kontroluje: dokładnie
jeden BOM w całym pliku, wyłącznie CRLF, końcowy CRLF, format `ID<TAB>tekst`,
1048 rekordów, brak zduplikowanych ID, brak U+FFFD. Liczenie wystąpień BOM
w całym pliku zamyka klasę błędów, która przechodziła po cichu — podwójny BOM
nie wykrywał żaden wcześniejszy skrypt. Test regresyjny sprawdza 6 uszkodzeń
na własnych fixture'ach, w tym podwójny BOM.

**S5 — zgodność formy wielokropka z konwencją języka**
(`tools/audyt_i18n_nietlumaczone.ps1`) — FR `…` (U+2026), pozostałe katalogi
`...`, EN wyłączony (jest kluczem kontraktu `.dfm` / `T()`). Świadomie bez
tabeli wyjątków: każdy rozjazd to błąd treści, a nie „zaakceptowana decyzja".
Stan wejściowy **0 naruszeń w 8 katalogach** (111× `...` w EN i 7 tłumaczeniach,
111× `…` we FR), więc reguła jest detektorem regresji, a nie tabelą dopasowaną
do bieżących danych.

**Audyt formy językowej** (`tools/audyt_linguistic_qa.ps1`) — osobny, tylko do
odczytu raport poza istniejącym S1–S5. Obejmuje 9 katalogów (z EN jako
kontraktem) i raportuje: interpunkcję hiszpańską na początku zdania (`¿` `¡`),
formę cudzysłowu per język, wielokropki oraz — informacyjnie — separatory
liczbowe. Raport w `tools/tmp/linguistic_qa.txt`.
- konwencje cudzysłowów są **zatwierdzoną tabelą binarną** (bez wyjątków):
  PL/CS/DE `„…”` (U+201E…U+201C), IT/ES/PT `«…»` (U+00AB…U+00BB, PT-PT =
  europejski). EN wyłączony — prosty `"` jest tam dopuszczalny jako klucz
  kontraktu `.dfm` / `T()`. **AF również wyłączony**: Afrikaans naśladuje
  konwencję brytyjską, więc zostaje przy prostym `"` (decyzja użytkownika
  2026-10-01). Pomiar katalogu AF potwierdza, że wyłączenie jest bezstratne:
  0 glifów typograficznych, 8 prostych cudzysłowów — dokładnie jak w EN
- **Pułapka Unicode:** w konwencji DE/CS U+201C pełni rolę **zamknięcia**, mimo
  nazwy `LEFT DOUBLE QUOTATION MARK` (wątek Unicode Mail List, Otto Stolz,
  2006). U+201D w PL/CS/DE to błąd, nie wariant. Reguła L3c wykrywa to
  pozycyjnie — po glifie otwarcia sprawdza, **który** glif parę zamyka.
- **stan po normalizacji: wszystkie reguły L1–L3 = 0 naruszeń** w 9 katalogach
- reguła L4 (separatory liczbowe) **nie została zaimplementowana** — pomiar
  katalogów nie znalazł realnych przypadków: jedyne kropki dziesiętne to
  specyfikatory `printf`, a grupowanie to zawsze `0`
- skrypt nie zmienia katalogów i nie przechodzi w tryb „fix" — ma być
  bezpiecznym detektorem, nie automatem edycji

**Jednorazowy skrypt normalizujący** (`tools/fix_fr_typography.ps1`) —
zamiana `U+202F` → `U+00A0` przed `:` oraz wewnątrz guillemetów. Uruchamiany
ręcznie, nie wbudowany w audyt. Zawiera twardą bramkę: liczba dwukropków
przed i po musi się zgodzić (dodana po incydencie, w którym pierwsza wersja
skryptu zjadła 189 znaków `:` — pętla `StringBuilder` zamieniała spację,
nie dokładając samego dwukropka; katalog odtworzony z `HEAD`, zweryfikowany
bajt po bajcie, `git diff` pusty).

**Jednorazowy skrypt normalizujący** (`tools/fix_quote_glifs.ps1`) — ujednolicenie
glifów cudzysłowu do zatwierdzonej tabeli: PL/CS/DE → `„…”`, IT/ES/PT → `«…»`,
plus `¡Aleluya! Por fin.` w hiszpańskim 625. **26 komórek** w 6 katalogach
(801 w IT/PT, 978/979/983/984 wszędzie, 625 w ES).
AF i EN celowo nietknięte — oba katalogi mają wyłącznie proste `"`.
Skrypt wyposażony w cztery bramki: integralność TSV przed i po, **round-trip**
(odwrócenie zamiany musi odtworzyć oryginał), niezmieniona liczba dwukropków,
raport każdej zmienionej komórki.
- dwie bramki okazały się konieczne — pierwsza wersja skryptu zawierała
  `$STRAIGHT = '"'` - '...' w PowerShell to single-quoted string, czyli
  dokladnie **jeden** znak, wiec sama definicja byla poprawna. Pierwsza wersja
  skryptu nie zapisywala przebudowanej wartosci z powrotem do zmiennej, stad
  `-split` niczego nie dzieli i skrypt raportowal "pary: 22 / zmienionych: 0".
  Druga wersja rekonstruowala wartosc przez
  `$parts -join`, co generowało **dodatkowe** cudzysłowy (`"""%s"?`) — złapane
  przez round-trip, zanim cokolwiek trafiło na dysk. Dopiero wersja
  podmieniająca znaki w miejscu (`Substring`, od prawej do lewej) przeszła
  wszystkie bramki; najpierw zweryfikowana na kopbach w `tools/tmp/probe*`
- reguła L3c z pierwszej wersji audytu zgłaszała **fałszywe naruszenie** na
  poprawnym niemieckim 801: skanowała cały string w poszukiwaniu „obcych"
  glifów, więc samo poprawne `„` otwarcie było uznane za złe zamknięcie.
  Przepisana na wykrywanie pozycyjne i pokryta 11 przypadkami testowymi
  (`tools/tmp/test_l3c.txt`) — łapie pułapkę U+201D i nie reaguje na poprawne
  pary w żadnym z 7 języków

### Changed

**Dokumentacja VCL poza katalogiem tymczasowym** (`doc/help/`, `.gitignore`,
`notatka zrodel dokumentacji`) — dekompresja CHM-ów IDE (`hh.exe -decompile`,
42 153 pliki / 473 748 303 B) przeniesiona z `tools/tmp/chm/` do
`doc/help/topics/` + `doc/help/vcl/`. Ścieżka `tools/tmp/` sugerowała zasób
jednorazowy, a to jest **jedyna lokalna referencja API VCL** w projekcie —
`doc/` poza tym katalogiem nie zawiera ani jednego pliku `.htm`. Przeniesienie
to rename w obrębie woluminu `C:`: liczba plików i suma bajtów przed oraz po
identyczne, nic nie skopiowano ani nie utracono.
- potwierdzona proweniencja: oryginalne `topics.chm` (109 404 388 B) i
  `vcl.chm` (41 690 586 B) leżą w `Studio\37.0\Help\Doc\`; mtime wszystkich
  rozpakowanych plików = mtime odpowiedniego CHM-a co do sekundy
  (`topics` 2026-06-08 19:38, `vcl` 2026-04-25 01:18)
- poprawiony błędny licznik w notatce: 43 079 → **42 153** (10 866 + 31 287).
  To był błąd zapisu, nie brakujące pliki
- `notatka zrodel dokumentacji` podaje teraz lokalne ścieżki do obu CHM-ów oraz
  sposób odtworzenia **bez sieci**; docwiki zostaje jako fallback na wypadek
  zniknięcia instalacji IDE
- `doc/help/` dopisane do `.gitignore` (linia 33)
- **rozpakowane dwa kolejne CHM-y** z tej samej instalacji: `system.chm` →
  `doc/help/system/` (20 779 plików, referencja RTL — `Classes` 1 865,
  `SysUtils` 1 504, `System.Types` 520) oraz `codeexamples.chm` →
  `doc/help/codeexamples/` (1 756 plików). Stan `doc/help/` to teraz
  **64 688 plików / 669 544 870 B** w czterech katalogach
- **`hh.exe -decompile` przestał działać** na tej instalacji Windows
  (10.0.26100, build 26100): kończy się bez błędu, exit code pusty, tworzy
  0 plików — sprawdzone na najmniejszym CHM (`dinkumware.chm`, 859 KB) dwoma
  sposobami wywołania (PowerShell `&`, `cmd /c start /wait`). Notatka podawała
  tę zepsutą instrukcję jako jedyny sposób odtworzenia; zastąpiona przez
  `7z x <plik.chm> -o<katalog> -y` (7-Zip 26.03, `Type = Chm`). 7-Zip
  zachowuje znaczniki czasu z CHM, więc dowód proweniencji działa tak samo
- zapisany brak w dokumentacji: **`TSkSVGDOM` nie występuje w żadnym**
  z czterech CHM-ów (0 trafień). Dokumentacja Skia siedzi w `vcl.chm`
  (702 pliki `Vcl.Skia.*`), ale dotyczy starszej jednostki `Vcl.Skia`.
  Deklaracja, której projekt faktycznie używa, jest w
  `source\rtl\common\System.Skia.pas` — `TSkSVGDOM = class(TSkReferenceCounted,
  ISkSVGDOM)` w linii **3641** (jednostka 13 456 linii). **Ścieżka bywa myląca:**
  to `source\rtl\common\`, nie `source\vcl\`, gdzie leży starsza
  `Vcl.Skia.pas` (6 837 linii) będąca tylko konsumentem `TSkSVGDOM.Make`
  (linia 2072)

**Tłumaczenia** (`i18n/*.tsv`, `uI18n.pas`) — 67 poprawionych komórek w 8
katalogach, wynik audytu wartości (nie bramki kontraktowej):
- błędy treści: PL 642 „CMYK misregistration" → „Siła przesunięcia:",
  PL 497 „Amiga Gradient" → „Amiga gradient" (jak w EN), FR 428
  „Vignette" → „Miniature", klucz 731 „Smooth preview scaling" w 6 językach
  (FR/DE/IT/ES/PT/AF — wcześniej błędnie tłumaczone z „Performance
  measurement")
- brakujący wielokropek w 11 komórkach: 598 (FR/DE), 609 (CS/FR/DE/IT/ES/PT/AF),
  1022 (CS/AF) — wyrównanie z EN „Relief…", „Emergo…", „Stereogram…"
- hiszpański: 26 kluczy z utraconym znakiem (`Tamano`→`Tamaño`,
  `Anadir`→`Añadir`, `Pequeno`→`Pequeño`, `Diseno`→`Diseño`) oraz 471/593 —
  odwrócona interpunkcja `?Desea` → `¿Desea`
- usunięto 18 końcowych spacji (PL 7, CS 2, FR 1, IT 2, ES 3, PT 3) oraz
  zbędne dwukropki w PL 804/805 (EN „Color depth" / „Loading engine" —
  dwukropka w EN nie ma)

**Typografia francuska** (`i18n/french.tsv`, `uI18n.pas`) — 400 komórek
znormalizowanych wg reguł z dokumentu „Typografia francuska". EN **nie**
zostało zmienione: tekst angielski jest kluczem kontraktu `.dfm` / `T()`, więc
konwersja EN wymagałaby przebudowy kluczy i jest osobnym tematem.
- apostrofy: 127 komórek `'` (U+0027) → `’` (U+2019)
- wielokropek: 101 komórka `...` → `…` (U+2026). Francuski staje się przez to
  jedynym językiem z U+2026 — decyzja świadoma: dokument uzasadnia ją
  zgodnością z EN, a EN faktycznie ma 111× `...` i 0× `…`
- spacje nierozdzielające przed `:`: 184× `U+202F` → `U+00A0` (162 komórki
  wcześniej dostawały `U+202F` zamiast `U+0020`, 22 z `U+202F` zamiast `U+00A0`),
  oraz 5 wstawionych tam, gdzie spacji nie było wcale (1046, 1047, 1048, 1058,
  1063) — **korekta pierwszej wersji tej normalizacji**, patrz niżej
- spacje wąskie przed `?` / `!`: 9× `U+202F` (bez zmian)
- cudzysłowy: 5 komórek (801, 978, 979, 983, 984) — `U+202F` → `U+00A0`
  po `«` i przed `»`
- **KOREKTA — podziału znaków nie rozumiał pierwszy przebieg.** OQLF
  (Vitrine linguistique, organ rządowy Quebecu) rozróżnia dwie kategorie
  i przypisuje je różnym Unicode: `vitrinelinguistique.oqlf.gouv.qc.ca/24565`
  — *« L'espace insécable [...] est employé avant ou après certains signes de
  ponctuation, comme les chevrons, le deux-points et les guillemets »*
  oraz *« L'espace fine est une espace insécable réduite utilisée devant le point
  d'interrogation, le point d'exclamation et le point-virgule »*;
  tabela `/22039` — *« Deux-points : Une espace insécable »*. Czyli dwukropek,
  procent i guillemety to `U+00A0`, a `;` `!` `?` to `U+202F`. Pierwszy przebieg
  trzymał `: ; ? !` razem pod `U+202F`, co było nadgeneralizacją reguły
  `espace fine` na dwukropek. Ta rozbieżność nie była widoczna w katalogu,
  bo procent od początku używał `U+00A0` — teraz obie grupy są zgodne.
  Wariant kanadyjski (fr-CA / TERMIUM) dopuszcza brak spacji przed `;` `!` `?`;
  katalog jest europejski francuski, więc obowiązuje `U+202F`
- procent: 6 komórek (122–125, 630, 928) — spacja przed `%` → U+00A0.
  **Nie** ruszono 13 komórek ze specyfikatorami `printf` (`%s`, `%d`, `%.2f`)
- świadomie bez zmian: 758 i 765 (`U+00A0` przed em-dash — dokument francuski
  tego nie obejmuje)
- nietknięte: stosunek `1:1` w kluczu 121 — dwukropek cyfra:cyfra to nie
  interpunkcja
- **5 komórek (34–38)** — `100%`, `50%`, `25%`, `200%`, `400%` otrzymały
  U+00A0 przed `%`. Reguła **S4F** została przy okazji zaostrzona (wcześniej
  szukała wyłącznie spacji przed procentem, więc `100%` przechodziło) i sama
  znalazła te rozjazdy: były niespójne z kluczem 630 `Aperçu 100 %`
  poprawionym wcześniej. Świadomie nietknięte 606 `Échelle (%)` i 1025
  `Échelle du point [%]` — tam przed `%` nie stoi liczba, więc reguła ich
  nie dotyczy

**Audyt wartości** (`tools/audyt_i18n_nietlumaczone.ps1`)
- nowe sekcje S1 (tłumaczenie = angielskie źródło innego klucza), S2
  (wielokropek w tłumaczeniu, brak w EN) i kontrola spacji wiodących/końcowych
- S2 rozszerzone o znak `…` (U+2026) — dotąd widoczne były wyłącznie
  tłumaczenia zapisane trzema kropkami. Guardy formy: `1:1` nie jest
  dwukropkiem, a `%s` / `%d` / `%.2f` nie procentem
- skrypt nadal kończy `exit 0` dla **znaleziek wartości**, ale ułamek
  integralności TSV daje `exit 1` — uszkodzone kodowanie nie jest kwestią gustu
- **S4E** szuka teraz *braku* `U+00A0` przed `:`, **S4F** — *braku* `U+202F`
  przed `;` `?` `!` (wcześniej oba znaki szukały `U+202F` razem, co było błędem
  normatywnym — patrz *Typografia francuska*). Proporcja `1:1` wyłączona
  wyrażeniem cyfra:cyfra, bez wpisu w tabeli wyjątków
- przebudowa reguł wielokropka — dawne **S2R** i **S2X** usunięte wraz z
  notką „klasa udokumentowana, świadomie nietknięta". Zasada: pozycja menu,
  która otwiera okno, ma wielokropek; EN jest źródłem, więc to on rozstrzyga,
  które klucze go noszą, a tłumaczenie ma go powtórzyć:
  - **S2** — EN kończy wielokropkiem, tłumaczenie nie (było **71 pozycji**,
    po poprawce **0**)
  - **S3** — tłumaczenie kończy wielokropkiem, EN nie (było **22 pozycje**,
    po poprawce **0**: 478/479/766 w 7 językach, 732 tylko w czeskim)
- **S4** — typografia francuska jako **osobna reguła wyjątku**: U+2019,
  U+2026, U+00A0 w cudzysłowach i przed `:`, U+202F przed `;` `?` `!`, procent,
  spacje wokół `…`. Reguła twarda, daje **0 naruszeń** — detektor regresji
- francuski **nie** jest wyłączony z S2/S3 — ma te same braki wielokropka co
  pozostałe języki. Wyjątkiem jest wyłącznie S4 (forma i odstępy), bo francuska
  typografia jest inna
- **forma wielokropka nie jest osobnym regulatem** — wynika z konwencji języka,
  zmierzonej na katalogach: PL 106× `...`, FR 102× `…`, pozostałe 6 około 100×
  `...`. Dawniej istniał tu dopuszczony wyjątek dla 826/828, bo te dwa rekordy
  miały U+2026 w 6 językach, a `...` wszędzie indziej. To anomalia danych, nie
  reguła — znormalizowano te **12 komórek** do `...` i **usunięto wyjątek**.
  Polski i francuski już były zgodne (PL `...`, FR `…`) i nie były ruszane
- **22 usunięte wielokropki** (`i18n/czech|french|german|italian|spanish|portuguese|afrikaans.tsv`) —
  tłumaczenia miały wielokropek tam, gdzie angielskie źródło go nie ma, więc
  pozycja menu nie otwiera okna. Dotyczy 4 ID:
  - **766** `Online documentation` — 7 języków (fr `…`, reszta `...`). Zakładka
    Pomoc: `Online documentation`, `Performance measurement`, `Launcher`,
    `Keyboard shortcuts`, `About` — żadna nie otwiera okna ustawień, więc
    wielokropka nie ma. Polski był jedynym poprawnym katalogiem
  - **732** `Performance measurement` — tylko czech
  - **478/479** `HAM6`/`HAM8 - … + Hold-Modify` — po 7 języków. Sekcja efektów,
    `mnuHAM6Click`/`mnuHAM8Click` stosują efekt, nie otwierają okna
  - `Hold-Modify` / `Hou-Wysig` to nazwa trybu, zawiera kropkę, ale nie jest
    wielokropkiem — nietknięta
  - polski i angielski **w ogóle nietknięte** (potwierdzone haszami)
  - Wynik etapu 1: **S3 22 → 0**, S2 bez zmian (71)
- **71 dopisanych wielokropków** (`i18n/*.tsv`, 8 katalogów) — etap 2, po
  zatwierdzeniu listy. Lista wyprowadzona **z danych** tą samą regułą co
  walidator (EN ma wielokropek, tłumaczenie nie), a nie z listy wpisanej na
  sztywno. Rozkład: pl 5, cs 9, fr 9, de 9, it 10, es 10, pt 10, af 9.
  Dotyczy 14 ID: 19, 55, 76, 80, 209, 570, 572, 584, 598, 684, 717, 821,
  1022, 1023 — to pozycje menu i okna otwierające okno ustawień
  - forma wg konwencji języka: PL `...`, FR `…` (U+2026), pozostałe 6 `...`
  - wyłącznie interpunkcja na końcu wartości — żadnej zmiany treści
- **Stan audytu po obu etapach: S1 0, S2 0, S3 0, S4 0**, spacje 0,
  bramka kontraktowa `exit 0`. Nie pozostało ani jednego wpisu w `$knownS2`
  ani `$knownS3` — obie tabele są puste
- 9 francuskich pozycji przeniesionych do `$known` w sekcji stem — `Vignette`,
  `Duotone`, `Interface`, `Timelapse`, `Tilt-shift (miniature)`, `ZX Spectrum`,
  `NES (Nestopia)`, `Game Boy — DMG / Pocket`, `C64 — Pepto / Colodore`.
  Francuskie słowa brzmiące identycznie jak angielskie, ta sama klasa co
  `Relief` i `Glitch`. Sekcja stem: 9 → 0 pozycji do rozważenia
- wyjątki z uzasadnieniem: 497 (wspólne słowo „gradient"), 609 (nazwa własna
  efektu), 294 PL/DE (sporny termin Halftone = Raster)

**Generator katalogów** (`tools/gen_i18n.ps1`)
- odczyt TSV zmieniony z gołego `Get-Content` na
  `[System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)`.
  PowerShell 5.1 czytał pliki jako ANSI, więc generator działał wyłącznie
  dzięki obecności BOM — jego utrata cicho zniszczyłaby diakrytyki PL/FR/DE/CS
  oraz znaki spoza ASCII (`…`, `’`, `U+202F`). Wynik bez zmian — po
  regeneracji `uI18n.pas` identyczny bajt w bajt

### Added

**Makra** (`uMacros.pas`, `fMain.pas`, 17 okien efektów)
- 18 nowych kodów w `cMacroLabels` (indeksy 43–60): STEREOGRAM, CHARCOAL,
  QUANTIZE, BOKEH, ENGRAVING, CROSSHATCH, HALFTONE, STIPPLE, DICE, RASTRCMYK,
  COLORIZE, SCREENPRINT, MAKIETA, LINOCUT, AGONY, AMIGAGRADIENT, AMIGABG,
  AMIGABGS
- rejestracja i odtwarzanie w 17 oknach: frmAgonyDlg, frmAmigaBGDlg,
  frmAmigaBGSDlg, frmAmigaGradientDlg, frmBokehDlg, frmCharcoalDlg,
  frmCrosshatchDlg, frmDiceDlg, frmEngravingDlg, frmHalftoneDlg,
  frmKolorowanieDlg, frmLinocutDlg, frmMakietaDlg, frmQuantizeDlg,
  frmRastrCmykDlg, frmScreenPrintDlg, frmStippleDlg

**Panel Zaznaczenia** (`frmSelDlg.dfm`, `frmSelDlg.pas`, `fMain.dfm/.pas`)
- pozycja menu Zaznaczanie przeniesiona na górę menu Narzędzia
- tytuł okna i etykiety przeniesione do i18n (1101 „Selection…", 1102
  „Selection", 1103 „Mask")
- `frmMain.DebouncedWandFromSeed` — tolerancja różdżki przestaje odświeżać
  podgląd na każdy tick suwaka
- `SelDlgInst.SyncStatus` wywoływane po `LoadImage`, `CloseImage` i
  `SetRetouchTolerance` — panel przestaje pokazywać nieaktualny stan
- naprawiony `.dfm` osadzony pod klasą `TSelDlg`

**Publikowanie** (`tools/build_dist.cmd`, `tools/build_msix.cmd`,
`Fotografista.dproj`, `AboutBoxUnit.pas`)
- skrypty `build_dist` i `build_msix` dla MSIX 1.1.0.0
- domyślna konfiguracja `Release` w projekcie
- „O programie" — `RealAppVersion = '1.1'`

**Bramka i18n** (`tools/audit_i18n.ps1`, `tools/gen_i18n.ps1`)
- nowy skrypt `audit_i18n.ps1` sprawdza, czy każdy napis w `Caption`/`Text`/
  `Hint` (`.dfm`), każdy literał `T('...')` (`.pas`) i każdy prefiks
  `T('...' + ...)` ma klucz EN w `english.tsv` — porównanie znak po znaku,
  z rozwikłaniem konkatenacji `'tekst' + #8212 + 'tekst'`
- sprawdza też zgodność wygenerowanego `uI18n.pas` z TSV (po tekstach EN)
- `gen_i18n.ps1` uruchamia bramkę przed zapisem (blokada przed pominięciem
  błędu) i po zapisie (potwierdzenie zgodności tabeli); przy błędzie kończy
  się kodem 1 i nie zapisuje `uI18n.pas`
- celowo nietłumaczone wartości (etykiety dysków, nazwy formatów, definicje
  tuszy, separatory) pomijane wzorcami; wyjątki wymagają jawnego wpisu
  w allowliście skryptu wraz z uzasadnieniem
- błędy `T()` przy braku klucza są ciche (zwracają angielski literał), więc
  bramka zamienia rozbieżność katalog ↔ UI w błąd kompilacji skryptu

**Panel Retusz — zamiana koloru** (`frmToolsDlg.dfm`, `frmToolsDlg.pas`,
`fMain.pas`)
- checkbox **Zachowaj modelunek cieni** (`chkRetainShading`), domyślnie
  włączony — jasność oryginału zostaje zachowana, a konwersja HSL zmienia
  tylko barwę i nasycenie
- klucz i18n 1113 „Retain shading" w 9 językach

### Changed

**Pędzel zamiany koloru** (`fMain.pas`, `bmColorReplace`) — powtarzalne
malowanie zamiast kumulowania farby
- bezwzględne przypisanie koloru (`P[X] := Mix`) zamiast mieszania oryginału z
  nowym — powtórne przejście daje ten sam piksel
- jasność liczona z bieżącego piksela, nie z `Pb`, więc powtórne przejścia nie
  ciemnią obrazu
- maska `pf8bit` `FStrokeReplace` blokuje ponowne trafienie piksela w obrębie
  jednego pociągnięcia; brak stanu między pociągnięciami i brak wpływu na
  historię
- **siła skaluje promień malowanego dysku** (0 = nic, 100 = pełny pędzel), a pas
  kolorów wybiera **wyłącznie tolerancja** — wcześniej przy sile 100 pas
  rozszerzał się do 255, więc suwak tolerancji był martwy w konfiguracji
  domyślnej
- `TfrmMain.RetouchEffectiveRadius` — jeden promień dla malowania, kroku stempli
  i pierścienia kursora; krok stempla równy promieniowi, więc ślad nie
  rozpada się na kropki przy małej sile
- `TBrushTool.MouseUp` oznaczone `virtual`, aby `TRetouchBrushTool` zwalniał
  maskę po zakończeniu pociągnięcia

**Panel Retusz** (`frmToolsDlg.dfm`, `frmToolsDlg.pas`)
- usunięta etykieta „Tool" nad selektorem rodziny — combo przesunięte do lewej
  krawędzi kolumny
- ujednolicone nazwy pędzli: „Paint brush", „Clone brush",
  „Color replacement brush"; etykiety kolorów „Color to replace" i
  „Replacement color"

**Menu** (`fMain.dfm`)
- przywrócona pozycja „Retouch…" w menu Narzędzia

**Tłumaczenia** (`i18n/*.tsv`, `uI18n.pas`, `frmAmigaBGDlg.dfm`,
`frmAmigaBGSDlg.dfm`, `frmRisoV3Dlg.dfm`)
- klucze 1101–1103 (panel Zaznaczenia), 1104–1108 („Batch processing",
  „Distort", „Load preset", „Save preset", „Fill color") oraz 1113
  („Retain shading") w 9 językach
- klucze 1114–1117 — podpowiedzi pozycji maski ochronnej w `fMain.dfm`
  („Protect the selected area from effects", „Remove protection from the
  selected area", „Shows protected areas with diagonal red overlay",
  „Remove all protected areas") w 9 językach
- poprawione 3 podpisy okien, które nie pasowały do istniejących kluczy EN
  przez wielkość liter, więc nigdy się nie tłumaczyły: `Amiga background`,
  `Amiga background (stretched, MagicWB)`, `Risograph v3`
- ujednolicona pisownia oznaczenia wersji Risographa — małe `v`, zgodnie
  z `Risograph v1...` i `Risograph v2...` w menu (21 wartości w 9 językach):
  - klucz 709 (pozycja menu, `fMain.dfm:612`) — EN `Risograph V3...` →
    `Risograph v3...`; towarzyszące mu 7 języków z wielkim `V` → małe `v`,
    polski `Risografia V3` → `Risografia v3...` (bez trzech kropek)
  - klucz 959 (tytuł `frmRisoV3Dlg.dfm`) — wielkie `V3` → małe `v3`
    we wszystkich 8 tłumaczeniach
  - klucze 708 i 937 — polski `Risografia V2` → `Risografia v2...` (klucz
    menu, bez kropek) i `Risografia v2` (tytuł okna)
  - klucz 936 (tytuł okna Risographa V1 ustawiany w `frmRisoDlg.pas:55`) —
    polski `Risografia V1` → `Risografia v1`; jedyny pozostały wielki `V`
    w katalogu
- uzupełnione brakujące tłumaczenia pozycji menu Risographa V3 (klucz 709),
  która jako jedyna z całej serii `v1`/`v2`/`v3` została w 6 językach
  w angielskim, mimo że bracia przetłumaczono: czech `Risograf v3...`,
  francuski `Risographie v3...`, niemiecki `Risografie v3...`,
  włoski `Risografia v3...`, hiszpański `Risografía v3...`,
  afrykański `Risografie v3...`
- ujednolicony czeski wariant określenia: klucz 959 `Risografie v3` →
  `Risograf v3`, bo czeskie 708/709/936/937 używają formy `Risograf`

**Repozytorium i narzędzia** (`.gitattributes`, `.gitignore`, `tools/`)
- `.gitattributes` — cel „świeży clone = dokładnie ten working tree":
  `* text=auto`, pliki binarne `-text`, `eol=crlf` dla Delphi/IDE i danych,
  `eol=lf` dla skryptów i dokumentacji, listy wyjątków dla plików o EOL
  przeciwnym do grupy oraz binarne DFM (TPF0)
- `.gitignore` — `tools/tmp/`, `tools/audyt_missing_keys.txt`
- `tools/audyt_i18n_nietlumaczone.ps1` — raport (nie bramka, zawsze kod 0)
  wartości pozostawionych w języku angielskim. Grupuje klucze po „stemie"
  (bez numeru wersji) i zgłasza te, które mają brata przetłumaczonego, a same
  zostały po angielsku — to wyłapało nieprzetłumaczoną pozycję menu
  Risographa V3. Uzasadnione wyjątki (`Glitch`, `Relief`, `Stereogram`,
  `WB 256`) są na liście z komentarzem; cokolwiek poza nią trafia do sekcji
  „NOWE, DO ROZWAŻENIA"
- `notatka zrodel dokumentacji` — skąd odtwarzać materiały RTL/VCL i skrypty
- rekonstrukcja `.git` z kopii oraz skrypt pakujący na pendrive
  (`spakuj_git_na_pendraj`)

### Removed

**Martwy kod** (`frmSelDlg.pas`, `uSelection.pas`, `frmWBDlg.pas`)
- `TSelDlg.SyncFromMain`, `TSelDlg.WindowTimer`, nieużywany `RowTop` w
  layoucie, zmienna `Y2` w pętli rysowania
- `frmWBDlg` — martwe `SrcW` i `SrcH`

---

## [08-09.2026] — wersja sklepowa

Nowe narzędzia korekcyjne, maska ochronna i próbnik w balansie bieli. Wersja
Delphi — przebudowa aplikacji, niezależna od wcześniejszej wersji Hollywood.

### Added

**Usuwanie tła**
- Usuwanie tła — wybór narożnika startowego i suwak tolerancji (`frmUsunTloDlg.pas`)

**Gumka**
- Gumka z trybami **Wymaż / Przywróć** — odwracalne w ramach jednego obrazu,
  operacja na masce alfa (piksele RGB nietknięte) (`TEraserTool`, `fMain.pas`)

**Nowy system zaznaczeń**
- Prostokąt, elipsa, lasso, różdżka z tolerancją (`uSelection.pas`,
  `THitShape = (hsRect, hsEllipse, hsLasso, hsWand)`)
- Podgląd zaznaczenia jako obrys (marching ants) albo maska (quick mask)
- Różdżka i lasso działają na masce bitowej, nie tylko prostokącie

**Panel retuszu — pędzle** (`frmToolsDlg.pas`, jeden zestaw z przełącznikiem trybów)
- Pędzel malowania — kumulujące krycie farbą (tryb spray)
- Pędzel klonujący — Alt+klik = próbka, malowanie kopią pikseli źródła
- Pędzel jasności — rozjaśnianie / przyciemnianie (dodge/burn), kumulatywny,
  skok jednego stempla ograniczony (`cRetouchMaxStep`), domyślna siła 10
- Pędzel ostrości — wyostrzanie / rozmywanie (`uConvolution`)
- Pędzel zamiany koloru — dwa kolory, dwa tryby: malowanie z próbki (LPM) i
  próbkowanie (PPM)
- Zalewanie, próbnik koloru, pędzel maski ochronnej
- Gumka (patrz wyżej) jako pierwsza pozycja zestawu
- Siła zapamiętywana osobno dla każdej rodziny pędzla

**Maska ochronna** (`fMain.dfm`, grupa menu „Protection mask")
- Ochrona zaznaczenia — zabezpiecza obszar przed efektami
- Cofnięcie ochrony z zaznaczenia
- Podgląd maski — czerwona kreskowana nakładka na chronionych obszarach
- Wyczyszczenie maski

### Changed

**Balans bieli** (`frmWBDlg.pas`)
- Próbnik — klik w punkt uznawany za biel, próbka uśredniona z otoczenia 5×5 px
  pobierana z oryginału w skali 1:1 (nie z pomniejszonego podglądu)
- Lupa 1:1 pod kursorem (120×120 px z krzyżem)
- Automatyczne tłumienie korekcji — kanały dochodzą do 80% drogi do
  neutralnego odcienia zamiast pełnego wyrównania, wartości suwaków
  wyliczane logarytmicznie

---

## Uwagi

- Rejestr commitów: `git log` w katalogu `Delphi/`.
- Plan rozwoju: `ROADMAP.md`.


