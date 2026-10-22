# Fotografista — budowanie paczki MSIX

Całość robi jeden skrypt: `tools\build_msix.cmd`. Uruchamia się go ręcznie,
ale dopiero po przebudowaniu konfiguracji **Release | Win64** w IDE Delphi.

## Co musi być przygotowane wcześniej

| Element | Ścieżka | W gicie? |
|---|---|---|
| Świeży build | `Win64\Release\Fotografista.exe` + `sk4d.dll` | nie (artefakt) |
| Katalog, z którego powstaje paczka | `packaging\x64\` (`AppxManifest.xml`, `[Content_Types].xml`, `Assets\`) | nie, `packaging/` jest w `.gitignore` |
| Certyfikat do podpisu | `certyfikat\fotografista.pfx` | nie, w `.gitignore` |
| Windows SDK | `makeappx.exe` i `signtool.exe` w `C:\Program Files (x86)\Windows Kits\10\Bin\<wersja>\x64` | — |

## Kroki skryptu

1. **Szukanie narzędzi SDK.** Skrypt przegląda wersje Windows Kits od
   najnowszej i bierze pierwszą, która ma `makeappx.exe`. Potem sprawdza, czy
   w tym samym katalogu jest `signtool.exe`.
2. **Sprawdzenie wersji** (`tools\check_version.ps1`). Jeśli wersje się nie
   zgadzają, skrypt kończy pracę. Porównywane są cztery miejsca:
   - `Fotografista.dproj`, sekcja `Cfg_1_Win64`, wartości `FileVersion`
     i `ProductVersion`. To jest **wzorzec**, bo tylko ta wartość trafia do
     EXE. Obie liczby muszą być takie same.
   - `AboutBoxUnit.pas`, stała `RealAppVersion` (3 składowe, `1.2.0`
     traktowane jako `1.2.0.0`).
   - `packaging\x64\AppxManifest.xml`, atrybut `<Identity Version=...>`.
     Ten numer widzi Microsoft Store.
   - `tools\build_msix.cmd`, linia `set VER=1.2.0.0`, z której powstaje nazwa
     pliku paczki.

   Przy niezgodności skrypt wypisuje plik, linię, obecną wartość i wartość
   docelową, a raport zapisuje do `tools\tmp\check_version.txt`. Ten krok
   dodano po tym, jak do Store trafiła paczka 1.0.6.0 z niezgodnymi numerami.
3. **Sprawdzenie plików wejściowych.** Muszą istnieć: EXE, `sk4d.dll`,
   `AppxManifest.xml` i PFX. Jeśli czegoś brakuje, skrypt się zatrzymuje.
4. **Hasło do PFX.** Skrypt pyta o nie w trakcie działania (`set /p`).
   Hasło nie jest nigdzie zapisane.
5. **Kopiowanie buildu.** `Fotografista.exe` i `sk4d.dll` z `Win64\Release`
   są nadpisywane w `packaging\x64`.
6. **Pakowanie:**

   ```
   makeappx pack /o /d packaging\x64 /p dist\Fotografista_<VER>_x64.msix /l
   ```

   Do paczki trafia cała zawartość `packaging\x64`, a starsza paczka o tej
   samej nazwie jest wcześniej usuwana.
7. **Podpis:**

   ```
   signtool sign /f certyfikat\fotografista.pfx /p <hasło> /fd SHA256 /v <paczka>
   ```

8. **Weryfikacja.** `makeappx unpack` rozpakowuje paczkę do
   `tools\tmp\msix_verify`, co przy okazji sprawdza podpis. Katalog jest
   potem usuwany.
9. Gotowy plik leży w `dist\Fotografista_<VER>_x64.msix`. Każdy błąd
   przerywa skrypt z kodem 1.

## Podbijanie wersji

Przed nową paczką trzeba zmienić numer we wszystkich czterech miejscach
z punktu 2:

- w `Fotografista.dproj` (w IDE: Version Info dla Win64 | Release),
- w `RealAppVersion` w `AboutBoxUnit.pas`,
- w `Identity Version` w `packaging\x64\AppxManifest.xml`,
- w `set VER=` w `tools\build_msix.cmd`.

**Uwaga — komentarz w kodzie przeczy skryptowi.** Komentarz w
`AboutBoxUnit.pas` mówi, że `RealAppVersion` nie zależy od numeru paczki
MSIX, który rośnie przy każdej submisji do Store. Tymczasem
`check_version.ps1` wymaga, żeby oba numery były takie same. Gdyby Store
wymagał nowego numeru paczki bez zmian funkcjonalnych, strażnik zablokuje
build, dopóki nie zostanie podbite także `RealAppVersion`.

## Wersja sklepowa a repozytorium publiczne

Przy wersji sklepowej najpierw uruchamia się `tools\check_version.ps1`,
a potem `Fotografista.dproj` trafia do publicznego repozytorium (release)
w tym samym commicie co reszta plików.
