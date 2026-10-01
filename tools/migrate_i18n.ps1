# migrate_i18n.ps1 — Faza 0: wyciąga TextTable z uI18n.pas do 9 plików TSV (i18n/*.tsv).
# Format TSV:  ID<TAB>tekst   (ID jawne liczbowe, stałe; 1..N w kolejności tablicy).
# Źródłem prawdy STAJĄ SIĘ pliki TSV; blok TextTable w .pas regeneruje gen_i18n.ps1.
# Użycie:  powershell -ExecutionPolicy Bypass -File tools\migrate_i18n.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root 'uI18n.pas'
$i18n = Join-Path $root 'i18n'

if (-not (Test-Path $src))  { throw "Nie znaleziono: $src" }
if (-not (Test-Path $i18n)) { New-Item -ItemType Directory -Path $i18n | Out-Null }

$raw = Get-Content $src -Raw
$start = $raw.IndexOf('TextTable: array')
if ($start -lt 0) { throw 'Nie znaleziono TextTable w uI18n.pas' }
$start = $raw.IndexOf('(', $start)
if ($start -lt 0) { throw 'Nie znaleziono poczatku tablicy' }
$end = $raw.IndexOf(');', $start)
if ($end -lt 0) { throw 'Nie znaleziono konca tablicy' }
$body = $raw.Substring($start + 1, $end - $start - 1)

# --- parser stanowy rekordów (EN,PL,CS,FR,DE,IT,ES,PT,AF) ---
$records = [System.Collections.ArrayList]::new()
$i = 0
$seenKeys = @{}
while ($i -lt $body.Length) {
  while ($i -lt $body.Length -and $body[$i] -ne '(') { $i++ }
  if ($i -ge $body.Length) { break }
  $i++  # za '('
  $r = [ordered]@{}
  while ($i -lt $body.Length) {
    if ($i + 2 -lt $body.Length -and $body.Substring($i, 2) -match '^[A-Z][A-Z]$' -and $body[$i+2] -eq ':') {
      $k = $body.Substring($i, 2)
      $j = $i + 3
      while ($body[$j] -notin @("'", '"')) { $j++ }
      $j++  # za cudzysłów
      $val = ''
      while ($j -lt $body.Length) {
        if ($body[$j] -eq "'") {
          if ($j + 1 -lt $body.Length -and $body[$j+1] -eq "'") { $val += "'"; $j += 2; continue }
          break
        }
        $val += $body[$j]; $j++
      }
      $r[$k] = $val
      $i = $j + 1
      if ($i -lt $body.Length -and $body[$i] -eq ')') { $i++; break }
    } else { $i++ }
  }
  if (-not $r.Contains('EN')) { continue }
  [void]$records.Add([pscustomobject]$r)
}

if ($records.Count -ne 932) {
  Write-Warning "Uwaga: sparsowano $($records.Count) rekordow (oczekiwano 932). Kontynuuje."
}

# --- walidacja: komplet pól i brak TAB/nowych linii ---
$langs = @('EN','PL','CS','FR','DE','IT','ES','PT','AF')
$bad = 0
foreach ($r in $records) {
  foreach ($L in $langs) {
    if (-not $r.PSObject.Properties[$L]) {
      Write-Warning "Brak pola $L dla EN='$($r.EN)'"; $bad++
    } elseif ($r.$L -match "`t|`r|`n") {
      Write-Warning "TAB/nowa linia w polu $L dla EN='$($r.EN)'"; $bad++
    }
  }
  if ($r.EN -eq '') { Write-Warning "Pusty EN w rekordzie"; $bad++ }
}
if ($bad -gt 0) { throw "Wykryto $bad problemow w danych - nie zapisuje plikow." }

# --- zapis 9 plików TSV: ID<TAB>tekst, UTF-8 BOM ---
$utf8bom = New-Object System.Text.UTF8Encoding($true)
$id = 0
$idByKey = @{}
$streams = @{}
foreach ($L in $langs) { $streams[$L] = $null }

try {
  $fname = @{
    EN = 'english'; PL = 'polish'; CS = 'czech'; FR = 'french'; DE = 'german'
    IT = 'italian'; ES = 'spanish'; PT = 'portuguese'; AF = 'afrikaans'
  }
  $writers = @{}
  foreach ($L in $langs) {
    $path = Join-Path $i18n ($fname[$L] + '.tsv')
    $writers[$L] = [System.IO.StreamWriter]::new($path, $false, $utf8bom)
  }
  $recordIdx = @{}
  for ($n = 0; $n -lt $records.Count; $n++) { $recordIdx[$n] = $records[$n] }

  # zapis w kolejności tablicy (ID = indeks+1)
  for ($n = 0; $n -lt $records.Count; $n++) {
    $rid = $n + 1
    foreach ($L in $langs) {
      $writers[$L].WriteLine("$rid`t$($records[$n].$L)")
    }
  }
  foreach ($L in $langs) { $writers[$L].Flush(); $writers[$L].Dispose() }

  Write-Output "Zapisano: $($records.Count) rekordow x $($langs.Count) jezykow."
  foreach ($L in $langs) {
    $path = Join-Path $i18n ($fname[$L] + '.tsv')
    Write-Output ("  {0}.tsv  {1} linii" -f $fname[$L], (Get-Content $path).Count)
  }
  Write-Output 'Nastepny krok: Faza 1 (dedup w TSV), potem gen_i18n.ps1.'
} finally {
  foreach ($w in $writers.Values) { if ($w) { $w.Dispose() } }
}
