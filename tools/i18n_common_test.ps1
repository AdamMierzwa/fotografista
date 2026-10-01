# i18n_common_test.ps1 - test regresyjny Test-TsvIntegrity
#
# Uzycie:
#   powershell -ExecutionPolicy Bypass -File tools\i18n_common_test.ps1
#
# Cel: udowodnic, ze Test-TsvIntegrity nie przecieka bledu, ktory wczesniej
# przeszedl po cichu - podwojny BOM. Testy pozytywne (fixture uszkodzony ->
# problem wykryty) sa wazniejsze niz testy negatywne (fixture poprawny ->
# brak problemow), bo to one zatrzymuja regresje.
#
# Fixture tworzone sa w tools\tmp\ i usuwane na koncu. Katalog jest zakladany
# z New-Item -Force, bo tools\tmp\ moze byc wyczyszczony.
#
# exit 0 = wszystkie przypadki zachowaly sie zgodnie z oczekiwaniem.

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $PSScriptRoot
$tmpd  = Join-Path $PSScriptRoot 'tmp'
. (Join-Path $PSScriptRoot 'i18n_common.ps1')

if (-not (Test-Path $tmpd)) { New-Item -ItemType Directory -Path $tmpd -Force | Out-Null }

$src    = Join-Path $root 'i18n\english.tsv'
$passed = 0
$failed = 0

function Check {
  param([string]$Name, [bool]$Condition, [string]$Detail = '')
  if ($Condition) {
    Write-Output ("  OK    {0}" -f $Name)
    $script:passed++
  } else {
    Write-Output ("  BLAD  {0}   {1}" -f $Name, $Detail)
    $script:failed++
  }
}

# Kopiuje angielski katalog i podmienia wariant bajtowy.
function New-Fixture {
  param([string]$Name, [scriptblock]$Mutate)
  $dst = Join-Path $tmpd $Name
  $b = [System.IO.File]::ReadAllBytes($src)
  $b = & $Mutate $b
  [System.IO.File]::WriteAllBytes($dst, $b)
  return $dst
}

$srcBytes = [System.IO.File]::ReadAllBytes($src)
$bom3 = [byte[]](0xEF, 0xBB, 0xBF)

Write-Output 'Test-TsvIntegrity - przypadki pozytywne (uszkodzony katalog MUSI byc zgloszony)'

# 1. podwojny BOM - dokladnie ten blad, ktory przeszedl wczesniejsze bramki
$f = New-Fixture 'test_podwojny_bom.tsv' { param($b) [byte[]]($bom3 + $b) }
$r = Test-TsvIntegrity -Path $f
Check 'podwojny BOM jest wykrywany' `
      ($r.Count -ge 1 -and ($r -join ' | ') -match 'BOM') `
      ("otrzymano: " + ($r -join ' | '))

# 2. brak BOM
$f = New-Fixture 'test_brak_bom.tsv' { param($b) $b[3..($b.Length-1)] }
$r = Test-TsvIntegrity -Path $f
Check 'brak BOM jest wykrywany' `
      ($r.Count -ge 1 -and ($r -join ' | ') -match 'BOM') `
      ("otrzymano: " + ($r -join ' | '))

# 3. same LF zamiast CRLF
$f = New-Fixture 'test_gole_lf.tsv' { param($b) $b -ne 0x0D }
$r = Test-TsvIntegrity -Path $f
Check 'gole LF zamiast CRLF jest wykrywane' `
      ($r.Count -ge 1 -and ($r -join ' | ') -match 'LF') `
      ("otrzymano: " + ($r -join ' | '))

# 4. brak koncowego CRLF
$f = New-Fixture 'test_bez_koncowego_crlf.tsv' { param($b) $b[0..($b.Length-3)] }
$r = Test-TsvIntegrity -Path $f
Check 'brak koncowego CRLF jest wykrywany' `
      ($r.Count -ge 1 -and ($r -join ' | ') -match 'CRLF') `
      ("otrzymano: " + ($r -join ' | '))

# 5. uszkodzone kodowanie (U+FFFD w srodku tekstu) - BOM musi zostac, inaczej
#    test sprawdzalby bledna kontrole
$f = New-Fixture 'test_fffd.tsv' { param($b)
  $s = [System.Text.Encoding]::UTF8.GetString($b, 3, $b.Length - 3)
  $s = [regex]::Replace($s, "`t", ([char]0xFFFD + "`t"), 1)
  $body = [System.Text.Encoding]::UTF8.GetBytes($s)
  [byte[]]($bom3 + $body)
}
$r = Test-TsvIntegrity -Path $f
Check 'U+FFFD jest wykrywane' `
      ($r.Count -ge 1 -and ($r -join ' | ') -match 'FFFD') `
      ("otrzymano: " + ($r -join ' | '))

# 6. zla liczba rekordow (obcięcie pliku)
$f = New-Fixture 'test_za_malo_rekordow.tsv' { param($b) $b[0..($b.Length-401)] }
$r = Test-TsvIntegrity -Path $f
Check 'bledna liczba rekordow jest wykrywana' `
      ($r.Count -ge 1 -and ($r -join ' | ') -match 'rekord') `
      ("otrzymano: " + ($r -join ' | '))

Write-Output ''
Write-Output 'Test-TsvIntegrity - przypadki negatywne (poprawny katalog MUSI przejsc bez glosu)'

# 7. wszystkie dziewiec katalogow realnych
foreach ($lg in @('english','polish','czech','french','german','italian','spanish','portuguese','afrikaans')) {
  $p = Join-Path $root "i18n\$lg.tsv"
  $r = Test-TsvIntegrity -Path $p
  Check "katalog $lg jest integralny" ($r.Count -eq 0) ("otrzymano: " + ($r -join ' | '))
}

# 8. kopia angielskiego bez zadnych zmian - krotka kontrola przeciw falszywym alarmom
$f = Join-Path $tmpd 'test_kopia_bezzmian.tsv'
[System.IO.File]::WriteAllBytes($f, $srcBytes)
$r = Test-TsvIntegrity -Path $f
Check 'niezmieniona kopia angielskiego przechodzi' ($r.Count -eq 0) ("otrzymano: " + ($r -join ' | '))

# sprzatanie fixture'ow
Get-ChildItem -Path $tmpd -Filter 'test_*.tsv' -File -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Output ''
Write-Output ("Zaliczonych: {0}   Niezaliczonych: {1}" -f $passed, $failed)
if ($failed -gt 0) { exit 1 }
exit 0
