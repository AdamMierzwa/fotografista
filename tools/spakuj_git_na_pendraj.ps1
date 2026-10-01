# spakuj_git_na_pendraj.ps1 - kopia katalogu .git na nośnik wymienny.
# Tak skopiowany .git pozwala na dowolnym komputerze (z zainstalowanym git)
# odtworzyć cały komplet źródeł - patrz odtworz_z_gita.ps1.
#
# Użycie:
#   powershell -ExecutionPolicy Bypass -File tools\spakuj_git_na_pendraj.ps1 -PendriveRoot E:\
#   (z domyślnym repo = katalog nadrzędny względem tools\, albo jawne -RepoPath)
#
# parametry:
#   -PendriveRoot [obowiązkowo] - litera/ścieżka nośnika, np. E:\
#   -RepoPath     [opcjonalnie] - ścieżka repo; domyślnie katalog zawierający tools\

param(
  [Parameter(Mandatory = $true)]
  [string]$PendriveRoot,
  [string]$RepoPath = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$srcGit = Join-Path $RepoPath '.git'
$relDest = 'Fotografista_git_backup'
$destBase = Join-Path ($PendriveRoot.TrimEnd('\')) $relDest
$dstGit = Join-Path $destBase '.git'

if (-not (Test-Path -LiteralPath $srcGit)) { Write-Error "Brak katalogu .git w: $RepoPath"; exit 1 }
if (-not (Test-Path -LiteralPath $PendriveRoot)) { Write-Error "Nośnik niedostępny: $PendriveRoot (czy podłączony?)"; exit 1 }

Write-Host "Kopiuję .git z  $srcGit"
Write-Host "            do  $dstGit"
New-Item -ItemType Directory -Path $destBase -Force | Out-Null

& robocopy $srcGit $dstGit /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null
$rc = $LASTEXITCODE
if ($rc -gt 7) { Write-Error "robocopy zwrócił kod $rc ($($rc -band 7))) - niepełna kopia"; exit 1 }
# kodry robocopy: bity 0-7 to częściowy sukces, wartość >7 = błędy realne

function Get-DirStats([string]$dir) {
  $files = Get-ChildItem -LiteralPath $dir -Recurse -File -ErrorAction SilentlyContinue
  return @{ Count = @($files).Count; Size = (@($files) | Measure-Object -Property Length -Sum).Sum }
}

$s = Get-DirStats $srcGit
$d = Get-DirStats $dstGit

Write-Host ""
Write-Host ("  pliki:    {0,7}  -> {1,7}" -f $s.Count, $d.Count)
Write-Host ("  rozmiar:  {0,10:N0} B -> {1,10:N0} B" -f $s.Size, $d.Size)

# sanity: czy kopia jest poprawnym repo i wskazuje ten sam HEAD
$srcHead = (& git -C $RepoPath rev-parse HEAD 2>$null)
$dstHead = (& git --git-dir=$dstGit rev-parse HEAD 2>$null)

$okSize = ($s.Count -eq $d.Count -and $s.Size -eq $d.Size)
$okHead = ($null -ne $dstHead -and $dstHead -eq $srcHead)

if ($okSize -and $okHead) {
  Write-Host "WERYFIKACJA OK - kopia kompletna. HEAD: $dstHead"
  Write-Host "Odtwarzanie na innym komputerze:"
  Write-Host "  powershell -ExecutionPolicy Bypass -File <sciezka>\odtworz_z_gita.ps1 -GitSource $( $destBase )"
} else {
  Write-Warning "WERYFIKACJA: NIEZgodnosc!"
  if (-not $okSize) { Write-Warning "  rozmiar/liczba plikow rozni sie - sprawdz nośnik (FAT32? /MIR?)" }
  if (-not $okHead) { Write-Warning "  HEAD kopii = $dstHead (oczekiwano $srcHead) - kopia moze byc niepelna" }
  exit 1
}