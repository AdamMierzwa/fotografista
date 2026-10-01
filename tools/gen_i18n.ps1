# gen_i18n.ps1 — Faza 2: generuje blok TextTable w uI18n.pas z 9 plików TSV.
# Źródłem prawdy są pliki i18n/*.tsv. Blok w .pas jest między markerami
#   // BEGIN GENERATED TEXTABLE ... // END GENERATED TEXTABLE
# i NIE wolno go edytować ręcznie.
# Użycie:  powershell -ExecutionPolicy Bypass -File tools\gen_i18n.ps1
# Walidacja: identyczne ID-set, brak duplikatów EN, brak pustych tłumaczeń,
#            brak TAB/nowej linii, poprawna liczba rekordów.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pas  = Join-Path $root 'uI18n.pas'
$i18n = Join-Path $root 'i18n'

# --- BRAMKA i18n: katalog <-> .dfm / T() w .pas ---
# Generowanie tabeli przy katalogu niespojnym z UI tylko rozmnozy blad: T()
# zwraca wtedy angielski litera(l) po cichu. Sprawdzamy PRZED zapisem, a po
# zapisie drugi raz - z kontrolą zgodnosci uI18n.pas z TSV.
$audit = Join-Path $PSScriptRoot 'audit_i18n.ps1'
if (Test-Path $audit) {
  Write-Host 'BRAMKA i18n (przed generowaniem)...'
  & powershell -ExecutionPolicy Bypass -File $audit -NoDrift
  if ($LASTEXITCODE -ne 0) { throw "Bramka i18n odrzucila stan katalogu (audit_i18n.ps1, kod $LASTEXITCODE). uI18n.pas nietkniety." }
} else {
  Write-Warning 'Brak tools\audit_i18n.ps1 - pominieto bramke i18n.'
}

$langs = @('EN','PL','CS','FR','DE','IT','ES','PT','AF')
$fname = @{
  EN = 'english'; PL = 'polish'; CS = 'czech'; FR = 'french'; DE = 'german'
  IT = 'italian'; ES = 'spanish'; PT = 'portuguese'; AF = 'afrikaans'
}

# --- Kontrola integralnosci katalogow (modul wspolny z audytami) -------------
# Ulamek BOM/CRLF/formatu konczy skrypt kodem 1, zanim powstanie jakikolwiek
# zapis do uI18n.pas - generator nie moze utrwic stanu uszkodzonego.
. (Join-Path $PSScriptRoot 'i18n_common.ps1')
foreach ($L in $langs) {
  Assert-TsvIntegrity -Path (Join-Path $i18n ($fname[$L] + '.tsv'))
}

# --- wczytaj TSV: ID -> tekst ---
$byLang = @{}
foreach ($L in $langs) {
  $path = Join-Path $i18n ($fname[$L] + '.tsv')
  if (-not (Test-Path $path)) { throw "Brak pliku: $path" }
  $map = @{}
  # ODCZYT: Encoding::UTF8 wykrywa i zdejmuje BOM, wiec skrypt nie polega
  # na tym, ze plik ma BOM - goly Get-Content czytalby ANSI i zniszczyl
  # polskie/francuskie/czeskie diakrytyki oraz znaki spoza ASCII (U+2026,
  # U+2019, U+202F). Zgodne z Read-Tsv w audyt_i18n_nietlumaczone.ps1.
  foreach ($line in [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)) {
    $parts = $line -split "`t", 2
    if ($parts.Count -ne 2 -or $parts[0] -eq '') { throw "Zła linia w $($fname[$L]).tsv: '$line'" }
    $map[$parts[0]] = $parts[1]
  }
  $byLang[$L] = $map
}

# --- walidacja: identyczne ID-sety ---
$base = [System.Collections.Generic.HashSet[string]]::new([string[]]$byLang['EN'].Keys)
foreach ($L in $langs) {
  $set = [System.Collections.Generic.HashSet[string]]::new([string[]]$byLang[$L].Keys)
  $missing = [System.Collections.Generic.HashSet[string]]::new($base); $missing.ExceptWith($set)
  $extra   = [System.Collections.Generic.HashSet[string]]::new($set);    $extra.ExceptWith($base)
  if ($missing.Count -gt 0) { throw "ID w EN.tsv bez odpowiednika w $($fname[$L]).tsv: $($missing -join ',')" }
  if ($extra.Count   -gt 0) { throw "Nadmiarowe ID w $($fname[$L]).tsv: $($extra -join ',')" }
}

# --- walidacja: duplikaty EN, puste tłumaczenia, TAB/nowe linie ---
$enSeen = @{}
foreach ($kv in $byLang['EN'].GetEnumerator()) {
  if ($enSeen.ContainsKey($kv.Value)) { throw "Duplikat EN: '$($kv.Value)' (ID $($enSeen[$kv.Value]) i $($kv.Key))" }
  $enSeen[$kv.Value] = $kv.Key
}
foreach ($L in $langs) {
  foreach ($kv in $byLang[$L].GetEnumerator()) {
    if ($kv.Value -eq '') { throw "Puste tłumaczenie $L dla ID $($kv.Key)" }
    if ($kv.Value -match "`t|`r|`n") { throw "TAB/nowa linia w $L dla ID $($kv.Key)" }
  }
}

$ids = @($byLang['EN'].Keys | Sort-Object { [int]$_ })
Write-Host "Rekordów: $($ids.Count)"

# --- generuj wiersze rekordów (format jak w oryginale: 3 wiersze na rekord) ---
$rows = [System.Collections.ArrayList]::new()
for ($n = 0; $n -lt $ids.Count; $n++) {
  $id = $ids[$n]
  $esc = @{}
  foreach ($L in $langs) { $esc[$L] = $byLang[$L][$id].Replace("'", "''") }
  $sep = if ($n -lt $ids.Count - 1) { ',' } else { '' }
  [void]$rows.Add("    (EN: '$($esc['EN'])'; PL: '$($esc['PL'])'; CS: '$($esc['CS'])';")
  [void]$rows.Add("     FR: '$($esc['FR'])'; DE: '$($esc['DE'])'; IT: '$($esc['IT'])';")
  [void]$rows.Add("     ES: '$($esc['ES'])'; PT: '$($esc['PT'])'; AF: '$($esc['AF'])')$sep")
}

# --- wstaw do uI18n.pas między markerami (operacja liniami, odporna na CRLF) ---
$content = [System.IO.File]::ReadAllText($pas, [System.Text.Encoding]::UTF8)
$lines = $content -split "`r`n"
$bi = -1; $ei = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -like '*// BEGIN GENERATED TEXTABLE*') { $bi = $i }
  if ($lines[$i] -like '*// END GENERATED TEXTABLE*')   { $ei = $i }
}
if ($bi -lt 0 -or $ei -lt 0) { throw 'Nie znaleziono markerów GENERATED w uI18n.pas' }
if ($ei -le $bi) { throw 'Błędna kolejność markerów' }

$newBlockLines = [System.Collections.ArrayList]::new()
[void]$newBlockLines.Add('  // BEGIN GENERATED TEXTABLE - nie edytować ręcznie, generuje tools\gen_i18n.ps1')
[void]$newBlockLines.Add("  TextTable: array[0..$($ids.Count - 1)] of TTextRec = (")
foreach ($r in $rows) { [void]$newBlockLines.Add($r) }
[void]$newBlockLines.Add('  );')
[void]$newBlockLines.Add('  // END GENERATED TEXTABLE')

$out = [System.Collections.ArrayList]::new()
for ($i = 0; $i -lt $bi; $i++) { [void]$out.Add($lines[$i]) }
foreach ($l in $newBlockLines) { [void]$out.Add($l) }
for ($i = $ei + 1; $i -lt $lines.Count; $i++) { [void]$out.Add($lines[$i]) }

$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($pas, ($out -join "`r`n"), $utf8bom)
Write-Host "Zapisano uI18n.pas: blok TextTable wygenerowany ($($ids.Count) rekordów)."

# --- BRAMKA i18n (po zapisie): potwierdzenie, że tabela faktycznie powstała ---
if (Test-Path $audit) {
  Write-Host ''
  Write-Host 'BRAMKA i18n (po generowaniu)...'
  & powershell -ExecutionPolicy Bypass -File $audit
  if ($LASTEXITCODE -ne 0) { throw "Wygenerowany uI18n.pas nie zgadza sie z TSV (kod $LASTEXITCODE)." }
}
