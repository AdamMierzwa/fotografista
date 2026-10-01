# ROADMAP — Fotografista (wersja Delphi)

Plan rozwoju na okres 2026-10 → 2027-09. Struktura wg zasad projektu:
- **brak warstw** — wszystko przez suwaki lub kliknięcia;
- **skupienie na trzech obszarach**:
  a. efekty oparte o historię fotografii, druku i komputerów,
  b. rzeczy rzadko używane współcześnie,
  c. rozwiązywanie realnych problemów (prostowanie skanów, druk z
     minimalnym białym, itp.).
- narzędzia mają pierwszeństwo; efekty — tylko jeśli są wyraziste;
- historyczne techniki fotografii już nie są dodawane (mało atrakcyjne na
  monitorze w oderwaniu od oryginalnych materiałów); druk — wyłącznie
  pojedyncze przypadki (np. Komiks).

---

## Potwierdzone funkcje

### Narzędzia pędzlowe (panel Retusz)
1. **Pędzel klonujący** — Alt+klik = próbka; malowanie kopią pikseli źródła.
   Wzorzec `TEraserTool`, wspólny suwak pędzla z `uCanvasTools.pas`.
2. **Pędzel szczegółów** — przełącznik trybu **rozmyj / wyostrz** + suwak
   siły (1–100); silnik `uConvolution`.
3. **Pędzel korygujący** — przenosi teksturę ze źródła, kolor dopasowuje do
   docelowego obszaru.
4. **Pędzel rozjaśniania / przyciemniania (Dodge/Burn)** — lokalna korekta
   jasności pędzlem.

### Efekty wyraziste / zapomniane
5. **Kalejdoskop** — stała liczba segmentów (6–12), bez pętli pikselowej.
6. **Spirograf (cykloidy)** — krzywe zębate/kołowe, proceduralne.
7. **Komiks** — złożenie obrysu + kwantyzacji.

### Rozwiązywanie problemów
8. **Korekta perspektywy** — zbieżność linii (np. budynki z dołu).
9. **Usuwanie czerwonych oczu** — automatyczne rozpoznanie jasnej plamki.
10. **Redukcja szumu skanów** z zachowaniem krawędzi (nie rozmazanie — osobne narzędzie).
11. **Automatyczne przycinanie do bladych krawędzi** (przy skanowaniu).
12. **Różdżka / zaznaczenie kolorem** — uzupełnienie selekcji prostokątnej.
13. **Descreening** — usuwanie moiry (powtarzalnego wzoru rastra) ze skanów druku.

---

## Utrzymanie (przy każdej wersji)
14. i18n (9 języków; TSV → `tools\gen_i18n.ps1`), BOM, audyt kluczy.
15. Kompilacja w IDE + testy proceduralne po każdej wersji.
16. Aktualizacje w sklepie po zamkniętych fazach.

---

## Odrzucone / świadomie pominięte
- **Warstwy** — w zakres poza plan (wszystko suwakami/kliknięciem).
- **Historyczne techniki fotograficzne** (daguerreotypia, ferrotypia,
  albuminowa, guma arabska, platyna itd.) — mało atrakcyjne na monitorze.
- **Druki historyczne** (ksero/Powielacz jest już jako Powielacz; reszta) —
  nie dodawać poza Komiksem.
- **LPI / prawdziwe DPI w eksporcie PDF** — sprzeczne z decyzją o maksymalnym
  zadrukowaniu strony (rezygnacja z DPI była celowa).
- **Timelapse „pro"** (jakość/CRF, normalizacja ekspozycji) — wydłuża
  renderowanie filmu.
- **Audyt różnic Hollywood → Delphi** — zbędny (różnice wynikają z ograniczeń
  Hollywood / wersji Amigowej — nie do wdrożenia).
- **Analogowy TV / skanowanie CRT** — już jest jako ustawienie efektu Glitch.