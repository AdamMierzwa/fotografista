# dedup_i18n.ps1 — Faza 1: usuwa duplikaty kluczy EN z 9 plików TSV.
# Dla grup identycznych zostaje najniższy ID. Dla grup różniących się: wybór z mapy $Keep.
# Użycie:  powershell -ExecutionPolicy Bypass -File tools\dedup_i18n.ps1

$ErrorActionPreference = 'Stop'
$i18n = Join-Path (Split-Path -Parent $PSScriptRoot) 'i18n'
$langs = @('english','polish','czech','french','german','italian','spanish','portuguese','afrikaans')

# --- wczytaj wszystkie pliki ---
$data = @{}
foreach ($L in $langs) {
  $data[$L] = @()
  $lines = Get-Content (Join-Path $i18n ($L + '.tsv'))
  foreach ($line in $lines) {
    $parts = $line -split "`t", 2
    $data[$L] += ,[pscustomobject]@{ ID = $parts[0]; Text = $parts[1] }
  }
}

# --- znajdź grupy duplikatów wg EN ---
$en = $data['english']
$enById = @{}
foreach ($r in $en) { $enById[$r.ID] = $r.Text }
$groups = $en | Group-Object Text | Where-Object Count -gt 1

# --- mapowanie wyboru dla grup ROZNE (EN -> ID do zachowania) ---
$Keep = @{
  'Rotate 180'                     = '383'
  'Width (px):'                    = '199'
  'Height (px):'                   = '200'
  'Without dither'                 = '217'
  'Intensity (0-100):'             = '227'
  'Emboss'                         = '394'
  'Levels'                         = '283'
  'Screen print'                   = '299'
  'Select type:'                   = '320'
  'Select arc angle:'              = '321'
  'Original'                       = '361'
  'Thermal'                        = '392'
  'No image loaded.'               = '475'
  'Save icon...'                   = '486'
  'Icon format:'                   = '488'
  'Selection: %d x %d'             = '553'
  'Done.'                          = '778'
  'Done'                           = '434'
  'Black'                          = '577'
  'Blue'                           = '579'
  'Prepare for screenprint (t-shirts)...' = '717'
  'Vivid'                          = '284'
  'Colorize'                       = '288'
  'Halftone'                       = '294'
  'Image info'                     = '16'
}

$removeIds = [System.Collections.Generic.HashSet[string]]::new()

foreach ($g in $groups) {
  $ids = @($g.Group | ForEach-Object { $_.ID })
  if ($g.Name -eq 'Select type:') {
    Write-Host "UWAGA: 'Select type:' ID320 ma DE='Intensität wählen:' (błędne) - do poprawy po dedup."
  }
  if ($Keep.ContainsKey($g.Name)) {
    $keepId = $Keep[$g.Name]
    if ($ids -notcontains $keepId) { throw "Keep '$keepId' nie istnieje w grupie '$($g.Name)'" }
    foreach ($id in $ids) { if ($id -ne $keepId) { [void]$removeIds.Add($id) } }
  } else {
    # grupa identyczna -> zostaje najniższy ID
    $min = ($ids | Sort-Object { [int]$_ })[0]
    foreach ($id in $ids) { if ($id -ne $min) { [void]$removeIds.Add($id) } }
  }
}

Write-Host "Usuwam ID: $($removeIds.Count) z każdego z $($langs.Count) plików."

# --- zapisz z usuniętymi ID (kolejność rosnąca ID) ---
foreach ($L in $langs) {
  $kept = $data[$L] | Where-Object { -not $removeIds.Contains($_.ID) } | Sort-Object { [int]$_.ID }
  $path = Join-Path $i18n ($L + '.tsv')
  $sb = [System.Text.StringBuilder]::new()
  foreach ($r in $kept) { [void]$sb.AppendLine("$($r.ID)`t$($r.Text)") }
  $utf8bom = New-Object System.Text.UTF8Encoding($true)
  [System.IO.File]::WriteAllText($path, $sb.ToString(), $utf8bom)
  Write-Host ("  {0}.tsv: {1} linii" -f $L, $kept.Count)
}
Write-Host 'Dedup zakończony.'
