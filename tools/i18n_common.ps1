# i18n_common.ps1 - wspolne kontrole integralnosci katalogow i18n/*.tsv
#
# Modul bez zaleznosci. Uzywany przez:
#   tools\gen_i18n.ps1                 (Assert-TsvIntegrity)
#   tools\audit_i18n.ps1               (Assert-TsvIntegrity)
#   tools\audyt_i18n_nietlumaczone.ps1 (Read-TsvChecked)
#   tools\i18n_common_test.ps1         (Test-TsvIntegrity)
#
# Po co to istnieje: katalogi TSV maja byc UTF-8 z DOKLADNIE jednym BOM,
# wylacznie CRLF, 1048 rekordow w formacie "ID<TAB>tekst" i koncowy CRLF.
# Wczesniejsze bramki sprawdzaly tylko to, czy tekst sie daje przegwiazc -
# uszkodzone kodowanie (np. podwojny BOM) przechodzilo po cichu.
# Kontrola "dokladnie jeden ciag EF BB BF w calym pliku" zamyka te klase bledu.
#
# Konwencja formatowania plikow .tsv: UTF-8 BOM + CRLF (patrz AGENTS.md regula 10).
# Ten modul jest UTF-8 z BOM, koniec linii LF (jak pozostale .ps1 w tools\).

$script:I18nExpectedRecords = 1048

# Zwraca liste problemow. Pusta lista = plik w pelni poprawny.
# Funkcja NIGDY nie konczy skryptu - decyzje podejmuje wolajacy.
function Test-TsvIntegrity {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [int]$Expected = 1048
  )

  $problems = New-Object System.Collections.Generic.List[string]

  if (-not (Test-Path -LiteralPath $Path)) {
    [void]$problems.Add('plik nie istnieje')
    return ,$problems
  }

  $bytes = [System.IO.File]::ReadAllBytes($Path)

  # 1. BOM na poczatku pliku
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  if (-not $hasBom) {
    [void]$problems.Add('brak BOM UTF-8 na poczatku pliku')
  }

  # 2. dokladnie jeden BOM w CALYM pliku (wykrywa podwojny BOM)
  $bomCount = 0
  for ($i = 0; $i -le ($bytes.Length - 3); $i++) {
    if ($bytes[$i] -eq 0xEF -and $bytes[$i+1] -eq 0xBB -and $bytes[$i+2] -eq 0xBF) { $bomCount++ }
  }
  if ($bomCount -ne 1) {
    [void]$problems.Add("wystapien BOM w pliku: $bomCount (oczekiwano dokladnie 1) - podwojny BOM albo uszkodzenie")
  }

  # 3. plik konczy sie CRLF
  if ($bytes.Length -lt 2 -or $bytes[$bytes.Length-1] -ne 0x0A -or $bytes[$bytes.Length-2] -ne 0x0D) {
    [void]$problems.Add('plik nie konczy sie CRLF')
  }

  # 4. brak golych LF (kazdy LF poprzedzony CR)
  $bare = 0
  for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($bytes[$i] -eq 0x0A -and ($i -eq 0 -or $bytes[$i-1] -ne 0x0D)) { $bare++ }
  }
  if ($bare -gt 0) {
    [void]$problems.Add("linie konczace sie golym LF zamiast CRLF: $bare")
  }

  # 5. tresc: U+FFFD, format ID, jeden TAB, duplikaty, liczba rekordow
  $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)

  $fffd = [regex]::Matches($text, [string][char]0xFFFD).Count
  if ($fffd -gt 0) {
    [void]$problems.Add("znakow U+FFFD (uszkodzone kodowanie): $fffd")
  }

  $lines = $text -split "`r`n"
  if ($lines.Count -gt 0 -and $lines[$lines.Count-1] -eq '') {
    $lines = $lines[0..($lines.Count - 2)]
  }

  $ids = @{}
  $badId = 0
  $badTab = 0
  $dup = 0
  foreach ($l in $lines) {
    if ($l -eq '') { continue }
    $parts = $l -split "`t"
    if ($parts.Count -ne 2) { $badTab++; continue }
    if ($parts[0] -notmatch '^\d+$') { $badId++; continue }
    if ($ids.ContainsKey($parts[0])) { $dup++ } else { $ids[$parts[0]] = $parts[1] }
  }
  if ($badTab -gt 0) { [void]$problems.Add("linie bez dokladnie jednego TAB: $badTab") }
  if ($badId  -gt 0) { [void]$problems.Add(('linie z ID poza formatem ^\d+$: {0}' -f $badId)) }
  if ($dup     -gt 0) { [void]$problems.Add("zduplikowane ID: $dup") }
  if ($lines.Count -ne $Expected) {
    [void]$problems.Add("liczba rekordow: $($lines.Count), oczekiwano $Expected")
  }

  return ,$problems
}

# Twarda bramka: przy ufamku integralnosci wypisuje diagnostyke i konczy skrypt
# kodem 1. Uzywane w skryptach, ktore czytaja TSV przed zrobieniem czegokolwiek.
function Assert-TsvIntegrity {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [int]$Expected = 1048
  )

  $p = Test-TsvIntegrity -Path $Path -Expected $Expected
  if ($p.Count -gt 0) {
    Write-Output ('ULAMEK INTEGRALNOSCI: ' + (Split-Path -Leaf $Path))
    foreach ($x in $p) { Write-Output ('   - ' + $x) }
    exit 1
  }
}

# Bramka + odczyt do hashtable (ID -> tekst). Zastepuje wlasny Read-Tsv.
function Read-TsvChecked {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [int]$Expected = 1048
  )

  Assert-TsvIntegrity -Path $Path -Expected $Expected

  $h = @{}
  foreach ($l in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
    if ($l -eq '') { continue }
    $p = $l -split "`t", 2
    if ($p.Count -eq 2) { $h[$p[0]] = $p[1] }
  }
  return $h
}
