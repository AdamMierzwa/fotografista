# audyt_ctx_expand.ps1 - ASCII only. Dodatkowe konteksty: .Title :=, ShowMessage, MessageBox
# w 7 plikach. Gole literaly poza T(). Wynik -> tools\tmp\audyt_ctx_expand.txt
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tmpd = Join-Path $root 'tools\tmp'
$out = Join-Path $tmpd 'audyt_ctx_expand.txt'

$files = @('fMain.pas','frmBatchDlg.pas','frmBenchmarkDlg.pas','uImageIO.pas',
           'uRiso.pas','frmShortcutsDlg.pas','frmAmigaBGDlg.pas')

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("DODATKOWE KONTEKSTY: .Title := / ShowMessage / MessageBox (gole literaly, poza T())")
[void]$sb.AppendLine("Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")

foreach ($fn in $files) {
  $path = Join-Path $root $fn
  if (-not (Test-Path $path)) { continue }
  $lines = Get-Content -Encoding UTF8 $path
  [void]$sb.AppendLine("== $fn ==")
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $t = $lines[$i]
    if ($t -match "\.Title\s*:=" -or $t -match '\bShowMessage\s*\(' -or $t -match '\bMessageBox\s*\(') {
      $tr = $t.Trim()
      if ($tr -match "'" -and $tr -notmatch "T\s*\(") {
        if ($tr.Length -gt 200) { $tr = $tr.Substring(0, 200) + '...' }
        [void]$sb.AppendLine("  $($i+1): $tr")
      }
    }
  }
}
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($out, $sb.ToString(), $utf8bom)
Write-Host "Saved: $out"