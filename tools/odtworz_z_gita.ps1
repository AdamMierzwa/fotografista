# odtworz_z_gita.ps1 - rekonstrukcja kompletu źródeł (compile-ready) z samego
# katalogu .git, np. skopiowanego na pendrive (patrz spakuj_git_na_pendraj.ps1).
#
# Dowód poprawności bez porównania z oryginałem (na obcej maszynie):
#   1) git fsck --full  (integralność obiektów)
#   2) git status --porcelain (working tree == HEAD bit-identycznie wg EOL z .gitattributes)
#   3) liczba plików w working tree == liczba plików śledzonych (git ls-files)
#   opcjonalnie: 4) kompilacja msbuild Fotografista.dproj (flaga -TestBuild)
#
# Użycie:
#   powershell -ExecutionPolicy Bypass -File tools\odtworz_z_gita.ps1 `
#       -GitSource E:\Fotografista_git_backup -Dest C:\Fotografista_odtworzone
#   (lub -GitSource wskazujący bezpośrednio folder .git; add -TestBuild by skompilować)
#
# parametry:
#   -GitSource [obowiązkowo] - katalog .git LUB katalog go zawierający (np. backup z pendrive)
#   -Dest      [opcjonalnie] - cel; domyślne = katalog obok źródła z przyrostkiem "_odtworzone"
#   -Branch    [opcjonalnie] - gałąź; domyślne = ta, na którą wskazuje HEAD źródła
#   -TestBuild [switch]      - po odtworzeniu uruchom msbuild Release/Win64 (jeśli znaleziony)

param(
  [Parameter(Mandatory = $true)]
  [string]$GitSource,
  [string]$Dest = '',
  [string]$Branch = '',
  [switch]$TestBuild
)

$ErrorActionPreference = 'Stop'

# --- 1. lokalizacja katalogu .git
if (-not (Test-Path -LiteralPath $GitSource)) { Write-Error "Nie znaleziono: $GitSource"; exit 1 }

$gitDir = ''
$projDir = ''
if ((Split-Path -Leaf $GitSource) -eq '.git') {
  $gitDir = $GitSource
  $projDir = Split-Path -Parent $GitSource
} elseif (Test-Path -LiteralPath (Join-Path $GitSource '.git')) {
  $gitDir = Join-Path $GitSource '.git'
  $projDir = $GitSource
} else {
  Write-Error "$GitSource to nie jest repozytorium ani katalog .git"; exit 1
}

# --- 2. git dostępny?
try { $gitVer = & git --version 2>$null } catch { $gitVer = $null }
if ($LASTEXITCODE -ne 0 -or -not $gitVer) { Write-Error "git nieobecny w PATH. Zainstaluj Git for Windows i uruchom ponownie."; exit 1 }
Write-Host "użyty git: $gitVer"

# --- 3. gałąź domyślna = wskazana przez HEAD źródła
if (-not $Branch) {
  $headRaw = Get-Content -LiteralPath (Join-Path $gitDir 'HEAD') -TotalCount 1 -ErrorAction SilentlyContinue
  if ($headRaw -match '^ref: refs/heads/(.+)$') { $Branch = $Matches[1] }
}
if (-not $Branch) { $Branch = 'master' }
Write-Host "gałąź: $Branch"

# --- 4. katalog docelowy (pusty / nowy — fail-fast)
if (-not $Dest) {
  $base = if ($projDir) { Split-Path -Parent $projDir } else { Split-Path -Parent $gitDir }
  $leafSrc = if ($projDir) { $projDir } else { $gitDir }
  $leaf = Split-Path -Leaf $leafSrc
  $Dest = Join-Path $base ($leaf + '_odtworzone')
}
if (Test-Path -LiteralPath $Dest) {
  $items = @(Get-ChildItem -LiteralPath $Dest -Force -ErrorAction SilentlyContinue)
  if ($items.Count -gt 0) { Write-Error "Dest nie jest pusty: $Dest (podaj nową ścieżkę -Dest)"; exit 1 }
}
Write-Host "cel: $Dest"

# --- 5. klon = rekonstrukcja (core.autocrlf=true = deterministyczny EOL, ten sam, co zweryfikowany bit-identycznie)
& git clone -q -c core.autocrlf=true --branch $Branch $gitDir $Dest
if ($LASTEXITCODE -ne 0) { Write-Error "git clone nie powiódł się (kod $LASTEXITCODE)"; exit 1 }

# --- 6. weryfikacja integralności
$failed = $false
Write-Host ""
Write-Host "--- weryfikacja ---"

& git -C $Dest fsck --full 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { $failed = $true; Write-Warning "fsck zgłosił problemy" }

$status = (& git -C $Dest status --porcelain)
if (@($status).Count -gt 0) {
  $failed = $true
  Write-Warning "working tree NIE jest czysty ($(@($status).Count) wpisów):"
  $status | ForEach-Object { Write-Host "  $_" }
} else {
  Write-Host "working tree == HEAD (czysty)"
}

$tracked = @(& git -C $Dest ls-files)
$onDisk = @(Get-ChildItem -LiteralPath $Dest -Recurse -File -Force | Where-Object { $_.FullName -ne (Join-Path $Dest '.git') -and $_.FullName -notlike (Join-Path $Dest '.git\*') })
if ($tracked.Count -ne $onDisk.Count) {
  $failed = $true
  Write-Warning "liczba plików: śledzonych=$($tracked.Count) vs na dysku=$($onDisk.Count)"
} else {
  Write-Host "liczba plików: $($tracked.Count) (zgodna)"
}

$head = & git -C $Dest rev-parse HEAD
$size = (@($onDisk | Measure-Object -Property Length -Sum).Sum)
Write-Host ""
Write-Host "HEAD: $head"
Write-Host "odtworzono: $($tracked.Count) plików, $([math]::Round($size/1MB,1)) MB"

if ($failed) {
  Write-Warning "WYNIK: NIEZPOMYSLNIE - patrz komunikaty powyżej"; exit 1
}
Write-Host "WYNIK: OK - źródła odtworzone kompletnie (można otworzyć Fotografista.dproj)."

# --- 7. opcjonalna kompilacja
if ($TestBuild) {
  Write-Host ""
  Write-Host "--- kompilacja (Release/Win64) ---"
  $msbuild = $null
  $cands = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Embarcadero\*\bin\MSBuild.exe'),
    (Join-Path $env:ProgramFiles 'Embarcadero\*\bin\MSBuild.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\*\*\MSBuild\Current\Bin\MSBuild.exe'),
    (Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio\*\*\MSBuild\Current\Bin\MSBuild.exe')
  )
  foreach ($c in $cands) {
    $hit = Get-Item $c -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
    if ($hit) { $msbuild = $hit.FullName; break }
  }
  if ($env:BDS) {
    $c = Join-Path $env:BDS 'bin\MSBuild.exe'
    if (Test-Path -LiteralPath $c) { $msbuild = $c }
  }
  if (-not $msbuild) {
    Write-Warning "MSBuild nieznaleziony - pomijam kompilację."
    Write-Warning "Zainstaluj RAD Studio / albo uruchom bez -TestBuild."
  } else {
    Write-Host "msbuild: $msbuild"
    & $msbuild (Join-Path $Dest 'Fotografista.dproj') /p:Config=Release /p:Platform=Win64 /t:Build /nologo
    if ($LASTEXITCODE -eq 0) { Write-Host "BUILD: OK" } else { Write-Warning "BUILD: kod wyjścia $LASTEXITCODE" }
  }
}