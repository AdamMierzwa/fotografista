# Changelog — Fotografista (wersja Delphi)

## [Następna wersja]

Różnica względem wersji sklepowej z 08-09.2026. Elementy już opisane w tej
sekcji — pędzle malowania, klonu, jasności i ostrości, siła per rodzina,
limit skoku dodge/burn, pędzel zamiany koloru, balans bieli, maska ochronna,
zaznaczenia, usuwanie tła — nie są powtarzane. Poniżej tylko to, co doszło
lub zmieniło zachowanie.

### Added

**Korekta perspektywy** (`uTransform.pas`, `frmPerspectiveDlg.pas`,
`frmPerspectiveDlg.dfm`, `fMain.pas`, `fMain.dfm`, `Fotografista.dpr`,
`i18n/*.tsv`, `uI18n.pas`) — nowe narzędzie w menu Korektor. Modalne okno
podglądu z czterema uchwytami narożników; przeciąganie ich na krawędzie
prostokąta usuwa zbieżność linii (perspektywa architektury, korekta kadru).
Podgląd odświeżany w trakcie przeciągania. Przekształcenie przez homografię
liczoną z prostokąta wyjściowego na czworokąt (`uTransform.pas`, macierz 3×3,
konwencja współrzędnych krawędziowych). Czworokąt wklęsły wykrywany przez
`QuadIsConvex` — wtedy warp zwraca `nil` i obraz zostaje bez zmian. Warp
wymaga 24-bitowego źródła. Maska alfa (wytarte miejsca) jest przekształcana
razem z obrazem, maska ochronna jest odtwarzana jako pusta, świadomie bez
przenoszenia geometrii zaznaczenia; Cofnij przywraca obie razem z obrazem. Ścieżka
macro pominięta (brak mapowania w `MacroCodeForOpName`). Dodane 4 klucze i18n
(ID 1122–1125) we wszystkich 9 katalogach; walidator integralności podniesiony
do 1056 rekordów.

**Wspólna bramka integralności katalogów** (`tools/i18n_common.ps1`,
`tools/i18n_common_test.ps1`) — moduł używany przez wszystkie trzy skrypty i18n
(`gen_i18n`, `audit_i18n`, `audyt_i18n_nietlumaczone`). Kontroluje: dokładnie
jeden BOM w całym pliku, wyłącznie CRLF, końcowy CRLF, format `ID<TAB>tekst`,
1056 rekordów, brak zduplikowanych ID, brak U+FFFD. Liczenie wystąpień BOM
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
  `$STRAIGHT = '"'`, co w PowerShell daje **dwa** znaki (podwójny cudzysłów
  delimituje string), więc `-split` niczego nie dzielił i skrypt raportował
  „pary: 22 / zmienionych: 0". Druga wersja rekonstruowała wartość przez
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

**„Zapisz jako" startował z rozszerzeniem w nazwie** (`fMain.pas`) — pole nazwy
otwierało się z pełną nazwą pliku (np. `obraz.png`); teraz startuje bez
rozszerzenia (`ChangeFileExt(FFilePath, '')`). Rozszerzenie nadal nadaje
wybrany format przy zapisie (`FilterIndex`), więc zapisany plik jest bez zmian.

**Wersja EXE nie zgadzała się z wersją paczki** (`Fotografista.dproj`) —
`FileVersion`/`ProductVersion` w `Win64|Release` stały na `1.0.6.0` od pierwszego
commita, m.in. w commitach „O programie: wersja 1.1" i „MSIX 1.1.0.0". Skutek
realny, nie teoretyczny: opublikowana paczka miała w manifeście `1.1.0.0`, a
`Fotografista.exe` w środku `1.0.6.0`. Ustawione `1.1.1.0`.
- `tools/check_version.ps1` — nowy strażnik krzyżujący cztery źródła numeru:
  `dproj` `Win64|Release` (referencja: `FileVersion` **i** `ProductVersion` w tej
  samej linijce, bo obie trafiają do EXE i obie widać we Właściwościach
  pliku), `RealAppVersion`, `AppxManifest` `Identity/@Version`, `set VER` w
  `build_msix.cmd`. Wypisuje plik, linię i wartość do poprawy. Brak pliku to
  „pominięto", nie błąd — `packaging/` jest gitignorowany, więc czysty clone
  nadal musi umieć zbudować paczkę ZIP
- `tools/test_check_version.ps1` — regresja na własnym drzewie w `tools\tmp\`
  (prawdziwe repo nietknięte). Trzy wstrzyknięte uszkodzenia: rozdzaj
  `FileVersion`/`ProductVersion` w jednej linijce, całkowity brak
  `ProductVersion`, stan czysty. 3/3
- `build_msix.cmd` woła strażnika jako **pierwszy** test sekcji „kontrola
  wejścia", przed kopiowaniem do `packaging\x64` i przed pytaniem o hasło;
  rozjazd kończy się `exit 1`. Twardy blok, nie ostrzeżenie: `1.0.6.0`
  przeszło całą ścieżkę publikacji aż do Storea właśnie dlatego, że nikt tego
  nie porównał
- `release/` ma `dproj` celowo na `1.1.0.0` (tag `v1.1`) i strażnik raportuje
  tam rozjazd. To prawda, nie usterka: `release/` nie służy do budowania, a
  numer faktycznie opublikowany nie może być cofnięty

**Skrypty buildowe były związane z jednym dyskiem** (`tools/build_msix.cmd`,
`tools/build_dist.cmd`, `tools/fix_buttons.ps1`, `tools/fix_fr_typography.ps1`,
`tools/fix_quote_glifs.ps1`, `tools/recover_buttons.ps1`,
`tools/recover_dfm.ps1`) — `C:\Fotografista\Delphi` zastąpione `%~dp0` (`.cmd`)
i `$PSScriptRoot` (`.ps1`), więc działają w każdym sklonowanym repo, niezależnie
od dysku. Wariant `.ps1` to wzorzec już obecny w 12 skryptach `tools/`.
- hasło do certyfikatu nie jest już zapisane w `build_msix.cmd`; bramka pyta je
  interaktywnie (`set /p`) i odmawia pakowania przy pustym

**Maska alfa nie podążała za obrazem przy zmianach geometrii** (`fMain.pas`) —
osiem nowych wrapperów `Alpha*` dla `FAlphaMask`, podpiętych wszędzie tam, gdzie
przepuszczano już `Prot*` dla `FProtMask`.
- `AlphaRotateLeft` / `AlphaRotateRight` / `AlphaRotate180` / `AlphaFlipH` /
  `AlphaFlipV` / `AlphaCrop` / `AlphaResize` / `AlphaResizeCrop` — geometria
  identyczna jak `Prot*` (te same indeksy, ten sam nearest-neighbour);
  dodatkowo każda oznacza `FAlphaDirtyRect` nowym prostokątem, bo
  `DrawCheckerRect` traktuje pusty rect jako „zero kosztu" i szachownica
  zostałaby stara
- odbicia: `ProtFlipH` / `ProtFlipV` były już w menu, ale makro wołało same
  prymitywy. `FLIPH` / `FLIPV` w `ApplyMacroStep` dostają teraz komplet, tak jak
  `ROTL` / `ROTR` / `ROT180`. `NotifyBitmapResized` **tu nie wchodzi** — flip nie
  zmienia wymiarów, a `UpdateZoomFit` zresetowałby zoom, którego użytkownik nie
  ruszał
- obrót o 90°, kadrowanie do zaznaczenia, resize i resize z przycięciem miały
  **tylko** `Prot*`. Po zmianie rozmiaru maska zostawała stara, a wartowniki
  rozmiaru w `DrawCheckerRect` i `DrawProtMaskOverlay` kończą wtedy rysowanie
  po cichu — objaw to brak nakładki przezroczystości, nie komunikat błędu
- ścieżka makra (`ApplyMacroStep`) wołała same prymitywy (`DoRotateLeft`,
  `DoRotateRight`, `DoRotate180`, `DoFlipH`, `DoFlipV`, `RotateAndCrop`) bez
  żadnego wrappera. Kroki `ROTL` / `ROTR` / `ROT180` / `FLIPH` / `FLIPV` /
  `STRAIGHTEN` dostają komplet teraz
- `RunMacro`: `UndoPush` → `UndoPushMasked(FBitmap, FAlphaMask, FProtMask)`.
  Bez tego dodanie masek do makra wprowadziłoby **drugi** błąd — cofniecie
  przywracałoby bitmapę, a zostawiało maskę obróconą. `UndoPushMasked` przyjmuje
  `nil` dla obu masek (`uUndo.pas:79-91`), więc kroki ich nie dotykające nie płacą
  za to nic
- nowa `NotifyBitmapResized` jako jedyna brama zmiany rozmiaru, wołana jawnie
  z każdego miejsca. Celowo **nie** wplatana w `FinishEffect` — maska potrzebuje
  kąta i geometrii, które zna tylko wywołujący, a `FinishEffect` otrzymuje
  wyłącznie nazwę operacji i czas. Świadomie pominięta przy obrocie 180° i
  odbiciach: nie zmieniają wymiarów, a `UpdateZoomFit` zresetowałby zoom,
  którego użytkownik nie ruszał
- `ProtResizeCrop` dostał pełną geometrię `ImageResizeCrop`
  (`uTransform.pas:153-159`) — liczy `ExcessW`, `ExcessH`, `CropX` i `CropY`
  z obu osi (`fMain.pas:6963-6973`), więc maska przycina tak samo jak obraz.
  Wcześniejsza wersja liczyła tylko `CropY` i w osi X nie przycinała wcale
- `AlphaRotateAngle`: `FAlphaDirtyRect` przeniesiony **przed** przypisaniem
  maski, żeby `FAlphaMask := NewMask` było ostatnią instrukcją w `try`. W drugą
  stronę wyjątek zostawiłby `except` ze zwolnieniem bitmapy już przypisanej do
  pola, czyli z wiszącym wskaźnikiem
- prostoowanie skanu: wywołanie `UpdateLayout` wprost w handlerze zamienione na
  `NotifyBitmapResized`, żeby szła ta sama ścieżka co przy resize i obrocie
- **rozważone, do osobnej decyzji:** przeniesienie obsługi masek do warstwy
  geometrii — `RotateAndCrop(Bmp, ProtMask, AlphaMask, Angle)` w
  `uTransform.pas`. Procedura ma tylko dwa miejsca wywołania (handler menu i
  ścieżka makra), więc zmiana podpisu jest tania i dałaby wszystkim wywołującym
  maskę za darmo, zamiast polegać na tym, że każde miejsce pamięta o trzech
  warstwach naraz. W tym etapie **niewdrożone**

**Kolejność narożników w oknie resize/crop jest celowa** (`frmResizeCropDlg.pas`) —
`rgCorner` ma `Columns = 2`, a VCL wypełnia grupę **kolumnami**, nie wierszami.
Kolejność pozycji (`frmResizeCropDlg.pas:45-48`) to celowo `Top-left`,
`Bottom-left`, `Top-right`, `Bottom-right`, żeby narożniki stały tam, gdzie są na
obrazie: lewy górny i lewy dolny w lewej kolumnie, prawy górny i prawy dolny w
prawej.
- wewnętrzna numeracja `Corner` w `ImageResizeCrop` (`uTransform.pas:153-159`) jest
  **wierszowa**: `0` = lewy górny, `1` = prawy górny (`CropX = ExcessW`),
  `2` = lewy dolny (`CropY = ExcessH`), pozostałe = prawy dolny. Nie pokrywa się
  z kolejnością pozycji w UI
- `VisualToCorner = (0, 2, 1, 3)` (`frmResizeCropDlg.pas:130`) to świadome
  tłumaczenie między tymi dwoma porządkami: `Bottom-left` → `2`, `Top-right` →
  `1`. **Nie jest błędem i nie powinno być upraszczane do identity** — przy
  mapowaniu 1:1 prawy górny wylądowałby w dole lewej kolumny, więc wybór
  wyglądałby jak z innego obrazu niż oglądany

**Lista motywów obcinała najdłuższą nazwę** (`frmInterfaceDlg.dfm`) —
`cmbTheme` (`Style = csDropDownList`) miał `Width = 200`. W tym trybie VCL bierze
szerokość rozwiniętej listy z `Width` (`TCustomComboBox.GetDropDownWidth`,
`Vcl.StdCtrls.pas:4527-4532` — gdy `FDropDownWidth = 0`, zwraca `Width`), więc
`Windows 10 Blue Whale LE`, najdłuższa nazwa w `TStyleManager.StyleNames`,
została ucięta bez możliwości rozszerzenia przez użytkownika.
- `Width` 200 → **224**, dobrane pod **maksymalną dozwoloną czcionkę 12 pt**
  (`spinFontSize.MaxValue = 12`): sam tekst to 201 px, dołożone 17 px na
  strzałkę rozwijania (`SM_CXVSCROLL`) i ~5 px marginesu. W zakresie 8–12 pt
  mieści się wtedy każda nazwa, a nie tylko przy 9 pt
- druga linia: `AutoDropDownWidth = True` — VCL poszerza listę do najszerszej
  pozycji sam, gdy `MaxItemWidth > Width` (`Vcl.StdCtrls.pas:4889-4915`),
  jako zabezpieczenie na przyszłe nazwy
- okno **nieposzerzone**: `16 + 224 = 240 < ClientWidth = 340`
- **pułapka:** samo `AutoDropDownWidth` nie dawało efektu — przy 9 pt tekst ma
  151 px, więc warunek `MaxItemWidth > Width` był fałszywy i VCL słusznie nic
  nie poszerzał. Nazwy motywów trzeba było mierzyć w **największej
  dozwolonej czcionce**, nie w domyślnej

**Suwaki: usunięte kreski podziałki** (`uTitleBar.pas`, `uCanvasTools.pas`) —
`TickStyle := tsNone` dla wszystkich 92 suwaków w 76 formularzach, **bez
wyjątku**.
- powód: `tsAuto` sam liczy gęstość kresek z `Min`/`Max` i szerokości kontrolki,
  więc dwa okna o różnych zakresach dostawały różną liczbę kresek — to
  `tsAuto` w działaniu, nie niespójność ustawień. Licznik pod suwakiem jest
  dokładniejszy niż podziałka
- przed zmianą `TickStyle` nie występował w **żadnym** `.dfm`; wszystkie suwaki
  brały wartość domyślną `tsAuto`
- nowy `TFotoForm.DisableTrackBarTicks`, wołany z `AfterConstruction` obok
  `ReflowTrackBarRows`. Iteracja **rekurencyjna** (`DisableTrackBarTicksIn`),
  bo 7 z 92 suwaków leży głębiej niż bezpośrednie dziecko formy — pętla po
  `Control` ich nie widzi
- `TBrushSizeSlider` (suwak rozmiaru pędzla, `uCanvasTools.pas`) to osobny
  komponent `TCustomControl`, niewidoczny z formy, więc ustawia `tsNone` sam
  w konstruktorze

**Pasek fokusu na suwaku przy otwarciu okna** (`uTitleBar.pas`) —
`TFotoForm.DoShow` ustawia `ActiveControl` na `btnOK`, a gdy go nie ma, na
`btnClose`.
- powód: `TTrackBarStyleHook.Paint` kończy się `if Focused then
  Canvas.DrawFocusRect(...)` — to bezpośrednie wywołanie GDI, nie element
  motywu Windows, więc na ciemnych motywach dawało białą kropkowaną ramkę
- **świadomie nie wyłączamy obwódki:** `DrawFocusRect` nie przyjmuje koloru,
  motyw jej nie obejmuje, a `TTrackBar` nie ma właściwości sterującej tym
  rysunkiem. Zmieniamy więc domyślny wybór fokusu, nie sam rysunek
- obwódka nadal pojawia się, ale dopiero po świadomym wejściu `Tabem` na
  suwak; nawigacja klawiaturowa nietknięta
- zabezpieczenie `FindComponent(...) is TButton` — nie wywala się na oknach
  bez tej kontrolki ani o inny typ klasy
- pokrycie **73 z 76** formularzy. Pominięte celowo `frmToolsDlg` (3 suwaki) i
  `frmSelDlg` (1 suwak) — pływające panele roboczne (R), nie dialogi modalne.
  `frmLauncherDlg` i `frmMain` mają 0 suwaków, więc ich nie dotyczy

**Kolejność przycisków OK / Anuluj** (`frmResizeCropDlg`, `frmResizeDlg`,
`frmTileDlg`) — trzy okna miały odwróconą kolejność `[Anuluj] [OK]`
względem pozostałych 67 okien z parą `btnOK` / `btnCancel`. Zamienione
`Left` i `TabOrder`, pary wyrównane do wzorca
`AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3)`.
- `.pas`: `AlignButtonsRight([btnCancel, btnOK], ...)` → `[btnOK, btnCancel]`
  w `frmResizeCropDlg.pas:122` i `frmResizeDlg.pas:139` — te dwa okna
  nadpisują `Left` w runtime przez `LayoutDialog`, więc poprawka samego
  `.dfm` byłaby zresetowana przy każdym otwarciu okna
- `.dfm`: `frmResizeCropDlg` 230↔321, `frmResizeDlg` 100↔191,
  `frmTileDlg` 150↔241. `Width = 85`, `Height = 25` i `Caption` bez zmian
- `frmTileDlg` poprawiony wyłącznie w `.dfm` — nie ma własnego kodu layoutu,
  pozycje przycisków pochodzą wprost z DFM
- `TabOrder` zamieniony tak, by tabulator szedł w kolejności wizualnej
  (najpierw OK, potem Anuluj), zgodnie z resztą okien
- stan po zmianie: 67 okien z parą w `.dfm` — wszystkie zgodne;
  `frmBenchmarkDlg` tworzy przyciski w kodzie i był zgodny od początku

**Globalne przeliczanie szerokości przycisków** (`uTitleBar.pas`,
`uI18n.pas`, `frmHistogramDlg`, `frmInterfaceDlg`, `frmKolorowanieDlg`,
`frmToolsDlg`, `frmTshirtDlg`) — nowa warstwa pomiaru szerokości z
treści, wspólna dla wszystkich okien, plus punkt zaczepienia `RefitButtons`
dla layoutu zależnego od czcionki i języka.
- `ButtonPad` = `2 * Canvas.TextWidth('W')` — margines poziomy liczony
  z fontu, wspólny dla `FitButton` i `FitButtonGroup`
- `FitButton(B, AMinWidth = 85)` = `Max(AMinWidth, TextWidth(Caption) +
  ButtonPad)`, `FitButtonGroup` wyrównuje grupę do najszerszego. Oba
  wołane po `TranslateForm`, więc uwzględniają długość tłumaczenia
- `RefitButtons` (`public`, `virtual`) przelicza parę `btnOK` / `btnCancel`
  we wszystkich oknach, gdzie para nosi te nazwy. Przycisk może **tylko
  urosnąć** (`Max(B.Width, potrzeba)`): nigdy nie mniejszy się i nie jest
  wyrównywany do najszerszego, więc 8 okien z celowo dobranym
  `Width = 80` zachowuje swoją szerokość, a `btnOK` nie skacze do 130 tam,
  gdzie jest wolna przerwa
- pozycja przesuwana wyłącznie przy realnym wyjściu poza prawą krawędź
  wspólnego rodzica (`Over := R - HostCtl.ClientWidth`) i tylko gdy para jest
  w prawej połowie kontenera — układ wycentrowany lub lewoszedny nietknięty.
  `Align <> alNone` → wyjście, bo VCL przelicza pozycję sam
- wyzwalacze: `DoShow`, nowy handler `CMParentFontChanged`, oraz
  `SetLanguage` / `ActiveFormChanged` w `uI18n.pas` — otwarcie okna, zmiana
  czcionki, zmiana języka. `uI18n.pas` dostał do `uses` `System.IOUtils`,
  `Winapi.Windows`, `uTitleBar`
- pięć okien nadpisuje `RefitButtons` własnym pomiarem (`btnAll`, `btnLum`,
  `btnClose`, `btnCanvasBG`, `btnPickColor`, `btnColorChoose`/`2`, grupa
  `btnInk0..5`) — wszystkie wołają `inherited`, więc para OK / Anuluj
  przeliczana jest również w nich
- pokrycie: 67 okien z parą `btnOK` / `btnCancel` w `.dfm`. `frmShortcutsDlg`
  ma tylko `btnOK`, `frmFileInfoDlg` tylko `btnClose` — bez zmian

**Okna „Zmień rozmiar" i „Przytnij" na layout liczony z treści**
(`frmResizeDlg.pas`, `frmResizeCropDlg.pas`, `frmResizeDlg.dfm`,
`frmResizeCropDlg.dfm`) — wymiary i pozycje liczone runtime, `.dfm`
zostaje wartością startową dla IDE.
- `FormCreate` woła `TranslateForm(Self)` **przed** pomiarem i dodaniem
  przetłumaczonych pozycji `rgCorner` — inaczej pomiar szedłby po angielsku.
  W `frmResizeCropDlg` usunięto ręczne liczenie szerokości `btnFullHD` przez
  `TBitmap`, zastąpiono `FitButton`
- nowa `LayoutDialog` w obu oknach: `StackBelow` łańcuchowo z `CtrlGap` /
  `RowGap` / `SectionGap` / `ButtonPad`, `FitButton`, `FitButtonGroup`,
  `AlignButtonsRight`, `FitToContent`, `FitHeight`
- `pnlAnchor.Top` i `pnlBottom.Top` liczone `StackBelow(..., SectionGap)`
  zamiast pozycji z `.dfm` — odpowiedź na zgłoszone ucinanie ogonka `p` przy
  12 pt; potwierdzenie wizualne po rebuildzie
- `LayoutDialog` wołana przed `ShowModal`, nie z `OnShow`, żeby
  `ShowResizeCropDlg` widział już poprawne rozmiary
- usunięto z `.dfm` `Align`, który nadpisywał pozycje liczone z treści:
  `alTop` na `pnlTop`, `alClient` na `pnlAnchor`, `alBottom` na `pnlBottom`
  oraz `alRight` na obu przyciskach `frmResizeCropDlg`. `ClientWidth` /
  `ClientHeight` w `.dfm` pozostają jako wartości startowe
- koszt: `frmResizeDlg` zwęża się z 420 do 290 px; `frmResizeCropDlg`
  zachowuje 420 px, ale etykiety `Width (px):` / `Height (px):` rosną
  z 83 / 79 do 105 px

**Layout okna „Jakość zapisu"** (`frmQualityDlg.pas`) — etykiety nachodziły na
suwaki przy większej czcionce, a wysokość okna była wpisana na sztywno.
- `TFotoForm.ReflowTrackBarRows` liczy suwaki tylko wśród **bezpośrednich**
  dzieci hosta (`uTitleBar.pas:459-475`). `TQualityDlg` nie nadpisuje
  `UseCustomTitleBar`, więc `ContentParent` = `Self`, a bezpośrednie dzieci to
  `gbJPEG` / `gbWebP` / `gbTIFF` / `btnOK` / `btnCancel` — `N = 0` i procedura
  wychodzi zanim policzy cokolwiek. Wszystkie trzy suwaki tego okna siedzą
  w `TGroupBox`, więc od lat nie było reflowu, `FitHeight` ani
  `AlignButtonsRight`
- `FormCreate` wywołuje nową `LayoutGroups`, która robi reflow **pojedynczo na
  każdą grupę** (każda ma płaski układ, więc algorytm helpera ma zastosowanie)
- wysokość każdej grupy liczona z realnego konturu jej ostatniego dziecka +
  `CtrlGap * 2` — zamiast wpisanych w `.dfm` `85` / `85` / `195` (`gbTIFF` miał
  26 px martwej przestrzeni przy 4 px w pozostałych grupach)
- `Top` grup i przycisków liczony **łańcuchowo**: `Poprzedni.Top +
  Poprzedni.Height + SectionGap`, akumulator startuje `Groups[0].Left`. Zero
  stałych `105` / `198`; przy innej czcionce i dłuższych tłumaczeniach wszystko
  wynika z treści
- `AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3)` aktywuje prawe
  wyrównanie przycisków (DFM miał `Left = 192` / `284`, helper daje 190 / 283)
- `FitHeight(CtrlGap * 3)` zamyka wysokość okna. `ClientWidth` celowo
  **pozostaje** z `.dfm` — `FitToContent` liczy tylko bezpośrednie dzieci, więc
  nie widziałby szerokości etykiet w grupach i dałby błędne 376 px
- koszt: przy 9 pt okno urośnie z 437 do ok. 476 px, przy 12 pt do ok. 503 px.
  Wiersze dostają realne odstępy (`RowGap` = `TextHeight div 3`) zamiast
  obecnych 1 px, za to przestają zależeć od rozmiaru czcionki — jak w 48
  pozostałych `TFotoForm` z suwakiem
- blok radia w `gbTIFF` (`rbLZW` / `rbNone` / `rbJPEG`) przesuwany o brakujący
  odstęp: `Shift := Max(0, lblTIFFCompression.Top + lblTIFFCompression.Height +
  RowGap - rbLZW.Top)`. `lblTIFFCompression` ma `AutoSize`, więc przy 12 pt jego
  dolna krawędź dochodziła dokładnie do `Top = 34` pierwszego radia — 0 px luku.
  `ReflowTrackBarRows` tego nie naprawia, bo jego druga seria
  (`uTitleBar.pas:573-586`) przesuwa wyłącznie kontrolki z `Top > LastLabelOrigTop`
  (108 px), a radia leżą wyżej. Przesunięcie jest `Max(0, …)`, więc przy 8 pt
  wynosi 0 i nic nie rusza; dolną granicę grupy i tak wyznacza czytnik suwaka,
  więc `Height` grupy i `ClientHeight` pozostają bez zmian
- **audyt** (`tools/tmp/audit_trackbar_nested.ps1` →
  `audit_trackbar_nested.txt`): 51 `TFotoForm` ma `TTrackBar`, z czego **48**
  ma go bezpośrednim dzieckiem formy (reflow działa), a **3** zagnieżdżony —
  `frmQualityDlg` (3 suwaki), `frmTshirtDlg` (`tbMinArea`, `tbCellMult`) i
  `frmWaterRippleDlg` (`trkStrength`, `trkDensity`). Te dwa ostatnie mają ten
  sam defekt i **nie zostały ruszone**
- helpera **nie** zmieniano: `ReflowTrackBarRows` w `uTitleBar.pas:433-639`
  szuka „następnej kontrolki pod ostatnią etykietą" po to, by ją przesunąć —
  iteracja w głąb `TGroupBox` przesuwałaby zawartość grup zamiast samych grup.
  Układ płaski jest założeniem algorytmu

**Layout launchera** (`frmLauncherDlg.dfm`, `frmLauncherDlg.pas`) — podpisy grup
`Zoom` i `Edit` były „przyklejone" do opisywanej treści, a prawy margines
wewnątrz grup wychodził o połowę za mały.
- `TCustomGroupBox.AdjustClientRect` (`Vcl.StdCtrls.pas:2180-2187`) robi
  `Inc(Rect.Top, Canvas.TextHeight('0'))` — podpis zajmuje pas u góry client
  area, więc dzieci grupy startują **pod** podpisem, nie obok niego. Oba
  panele miały pierwszy rząd na `Top = 18` przy `TextHeight = 15`, czyli
  **3 px** odstępu; przy dopuszczalnych 12 pt (`TextHeight` ~20) podpis
  nachodził na przyciski. Teraz `Top = 26` (odstęp 11 px przy 9 pt, 6 px
  przy 12 pt)
- `AdjustClientRect` wykonuje też dwa `InflateRect(Rect, -1, -1)`
  (`Ctl3D` = True), czyli `ClientWidth = Width - 4`. `FitButtons` liczył
  `Width := 8 + btn.Width + 8`, więc przy `btn.Width = 144` client = 156, a
  treść zajmowała 8..152 — prawy margines wychodził **4 px zamiast 8**.
  Poprawione na `12 + btn.Width + 8` (4 px ramki + 8 px marginesu)
- rozstaw w pionie: `grpZoom.Height` 74 → 92, `grpEdit` 88 → 92, `grpEdit.Top`
  130 → 148 (odstęp między grupami 16 px), okno `ClientHeight` 230 → 252,
  `ClientWidth` 172 → 176 i `ToolBar.Width` 172 → 176. Odstęp wierszy 6 px
  (`btnZoomFit` 44 → 57, `btnRevert` 48 → 57) — wcześniej w `grpZoom`
  pierwszy i drugi ród stykały się co 1 px
- bramka `tools/gen_i18n.ps1` przechodzi na zmodyfikowanym `.dfm`, `Caption`
  grup nietknięte, `uI18n.pas` bez zmian

**Naprawa podmiany tłumaczeń w kontrolkach i tytułach okien** (`uI18n.pas`,
`frmLauncherDlg.pas`, `i18n/polish.tsv`) — napisy zostawały w języku
poprzednim po zmianie języka.
- `TranslateControlTree` porównywał nowe tłumaczenie z **zapamiętanym
  oryginałem EN**, a nie z **bieżącym** napisem kontrolki. Gdy tłumaczenie
  jest identyczne z kluczem EN, warunek `if N <> Texts.Caption` był fałszywy,
  `SetPropValue` nie był wołany i kontrolka trzymała napis z poprzedniego
  języka. Objaw: grupa `Zoom` w panelu Wyrzutnia pozostawała `Powiększenie`
  po przełączeniu na EN/DE/FR/IT/ES/PT
- audyt `tools/tmp/audit_i18n_eq_en.ps1`: **141 z 1047 rekordów** ma w którymś
  języku tłumaczenie = EN, więc były potencjalnie zablokowane (`Zoom`, `OK`,
  `Sepia`, `Lasso`, `Amiga`, `MagicWB`, `Timelapse`, `Glitch`, `Raster`…).
  Poprawiony sam warunek, nie treść katalogów
- `TranslateForm` podmieniał `Caption` formy **w miejscu**, bez cache — tytuł
  okna zostawał na stałe w pierwszym języku, w którym został przetłumaczony.
  Oryginał trzymany jest teraz w `gControlOriginals` (`TForm` → `TControl`,
  sprzątanie przez `TI18nNotifier` działa bez zmian)
- `frmLauncherDlg.FormCreate` woła `TranslateForm(Self)`. Panel powstaje
  dopiero przy otwarciu Wyrzutni, czyli **po** `SetLanguage` w
  `Fotografista.dpr`, więc wcześniej tłumaczył go dopiero `FormActiveChanged`
- literówka w polskim katalogu: `Otwórzplik obrazu` → `Otwórz plik obrazu`
  (`i18n/polish.tsv`), przegenerowane `tools/gen_i18n.ps1` — bramka i18n OK
  przed i po, w bloku `TextTable` zmieniła się **jedna** linia

**Dokumentacja VCL poza katalogiem tymczasowym** (`doc/help/`, `.gitignore`,
`ZRODLA_DOKUMENTACJI.md`) — dekompresja CHM-ów IDE (`hh.exe -decompile`,
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
- `ZRODLA_DOKUMENTACJI.md` podaje teraz lokalne ścieżki do obu CHM-ów oraz
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

**Kursor pędzla — ustawienie wyglądu** (`uPrefs.pas`, `frmInterfaceDlg.pas`,
`frmInterfaceDlg.dfm`, `fMain.pas`, `i18n/*.tsv`) — Ustawienia > Interfejs
mają listę „Brush cursor" i pole krzyżyka w okręgu.
- `Circle outline` (domyślnie, dotychczasowe zachowanie) rysuje własny okrąg
  pędzla; `Crosshair (precise)` zostawia systemowy krzyżyk (`crCross`) bez
  okręgu. Dotyczy pędzla, gumki i maski ochronnej
- wybór zapisany jako indeks w `[Interface]\BrushCursorMode` (0/1, poza
  zakresem → 0), więc kolejność pozycji listy nie może się zmieniać
- pole „Show crosshair in brush outline" (`[Interface]\BrushCrosshairCenter`,
  domyślnie wyłączone) dorysowuje w środku okręgu krzyżyk dwukolorowy,
  tylko gdy promień ≥ 5 px. W trybie Crosshair pole jest wyszarzone, a jego
  stan zostaje zachowany
- zmiana działa od razu przy aktywnym pędzlu, gumce lub masce:
  `mnuSettingsInterfaceClick` wywołuje ponownie `Activate` narzędzia
- `UpdateBrushCursor` wychodzi na początku, gdy tryb ≠ 0, więc w trybie
  Crosshair próbnik też nie rysuje okręgu (wcześniej go rysował mimo `crCross`)
- klucze i18n 1118–1121 w 9 językach; licznik rekordów w bramce
  (`tools/i18n_common.ps1`) 1048 → 1052

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

**Adres dokumentacji online** (`fMain.pas`, `mnuHelpOnlineDocsClick`) — pozycja
otwiera stronę programu na własnej domenie zamiast strony dokumentacji wersji
Hollywood. Nazwa pozycji menu bez zmian, bo dokumentacja ma tam trafić

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
- `ZRODLA_DOKUMENTACJI.md` — skąd odtwarzać materiały RTL/VCL i skrypty
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


