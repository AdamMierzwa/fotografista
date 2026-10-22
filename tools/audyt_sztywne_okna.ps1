# audyt_sztywne_okna.ps1 - okna ze sztywnymi wymiarami (wbrew AGENTS.md:
# „ZAKAZ SZTYWNYCH WYMIAROW OKNA”). Po co: okno Jezyk mialo sztywne 280x320
# i ramke 250x265 - przy 12 pt i dluzszych tlumaczeniach obcinalo/zostawialo
# puste pasy (naprawione 2026-10-21).
#
# Zakres: sledzone przez git pliki *.dfm w katalogu projektu (bez podkatalogow)
# i odpowiadajace im *.pas, plus okna tworzone w kodzie (TForm.Create).
#   A) BRAK UKLADU Z ZAWARTOSCI - .pas nie wola FitToContent / FitHeight /
#      FitPreviewToDialog / LayoutDialog i nie liczy ClientWidth/ClientHeight;
#      rozmiar okna wylacznie z .dfm.
#   B) STALE W KODZIE - przypisania ClientWidth/ClientHeight := <liczba> albo
#      wyrazenie z liczba >= 50 (np. ClientWidth := pbox.Left + 400).
#   C) OKNA TWORZONE W KODZIE - TForm.Create z wymiarami/pozycjami podanymi
#      liczbami (Width/Height/Left/Top/ClientWidth/ClientHeight := liczba).
# Okno glowne (fMain, rozciagane) w A pominiete.
#
# Wynik: tools\tmp\audyt_sztywne_okna.txt (UTF-8 BOM). Uzycie:
#   powershell -ExecutionPolicy Bypass -File tools\audyt_sztywne_okna.ps1
# Ten plik jest UTF-8 z BOM, koniec linii LF (jak pozostale .ps1 w tools\).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Strip-Code([string]$s) {
  $s = [regex]::Replace($s, "\{[^}]*\}", { param($m) ($m.Value -replace '[^\n]', ' ') })
  $s = [regex]::Replace($s, "\(\*.*?\*\)", { param($m) ($m.Value -replace '[^\n]', ' ') }, 'Singleline')
  $s = [regex]::Replace($s, "//[^\n]*", '')
  $s = [regex]::Replace($s, "'[^'\n]*'", "''")
  return $s
}

$dfms = @(git ls-files '*.dfm' | Where-Object { $_ -notmatch '/' })
$layoutRx = '(?i)\b(FitToContent|FitHeight|FitPreviewToDialog|LayoutDialog)\b|\bClientWidth\s*:=|\bClientHeight\s*:='
$constRx = '(?i)\b(ClientWidth|ClientHeight)\s*:=\s*([^;]*)'

$A = New-Object System.Collections.Generic.List[string]
$B = New-Object System.Collections.Generic.List[string]
foreach ($d in $dfms) {
  $pas = [IO.Path]::ChangeExtension($d, '.pas')
  if (-not (Test-Path $pas)) { continue }
  $dfmText = [IO.File]::ReadAllText((Join-Path $root $d))
  if ($dfmText -notmatch '(?m)^\s*object\s+\w+\s*:\s*T\w+') { continue }
  $cw = [regex]::Match($dfmText, '(?m)^\s{2}ClientWidth\s*=\s*(\d+)').Groups[1].Value
  $ch = [regex]::Match($dfmText, '(?m)^\s{2}ClientHeight\s*=\s*(\d+)').Groups[1].Value
  $bs = [regex]::Match($dfmText, '(?m)^\s{2}BorderStyle\s*=\s*(\w+)').Groups[1].Value
  if ($bs -eq '') { $bs = 'bsSizeable' }
  $code = Strip-Code ([IO.File]::ReadAllText((Join-Path $root $pas)))
  if ($pas -ne 'fMain.pas' -and $code -notmatch $layoutRx) {
    $A.Add(('   {0,-28} {1}x{2}  {3}' -f $pas, $cw, $ch, $bs))
  }
  $ln = 0
  foreach ($line in ($code -split "`n")) {
    $ln++
    $m = [regex]::Match($line, $constRx)
    if ($m.Success) {
      $expr = $m.Groups[2].Value
      $nums = @([regex]::Matches($expr, '\b\d+\b') | ForEach-Object { [int]$_.Value })
      if ($nums | Where-Object { $_ -ge 50 }) {
        $B.Add(('   {0}:{1}  {2}' -f $pas, $ln, $line.Trim()))
      }
    }
  }
}

# C) okna tworzone w kodzie
$C = New-Object System.Collections.Generic.List[string]
$pasAll = @(git ls-files '*.pas' | Where-Object { $_ -notmatch '/' })
foreach ($p in $pasAll) {
  $code = Strip-Code ([IO.File]::ReadAllText((Join-Path $root $p)))
  $lines = $code -split "`n"
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $m = [regex]::Match($lines[$i], '(?i)(\w+)\s*:=\s*TForm\.Create')
    if (-not $m.Success) { continue }
    $var = [regex]::Escape($m.Groups[1].Value)
    $hits = New-Object System.Collections.Generic.List[string]
    for ($j = $i; $j -lt [Math]::Min($lines.Count, $i + 200); $j++) {
      if ($lines[$j] -match ('(?i)\b' + $var + '\.(ClientWidth|ClientHeight|Width|Height)\s*:=\s*\d+\s*;')) {
        $hits.Add(('{0}: {1}' -f ($j + 1), $lines[$j].Trim()))
      }
    }
    $C.Add(('   {0}:{1}  {2} := TForm.Create  (stale wymiary okna: {3})' -f $p, ($i + 1), $m.Groups[1].Value, $hits.Count))
    foreach ($h in $hits) { $C.Add('        ' + $h) }
  }
  # klasy formularzy tworzone w konstruktorze przez inherited CreateNew (bez .dfm)
  # - przypisania bez prefiksu zmiennej (ClientWidth := 430;); dodane 2026-10-21,
  # bo wczesniejsza wersja przeoczyla okna testu wydajnosci (frmBenchmarkDlg)
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -notmatch '(?i)\binherited\s+CreateNew\b') { continue }
    $hits = New-Object System.Collections.Generic.List[string]
    for ($j = $i; $j -lt [Math]::Min($lines.Count, $i + 120); $j++) {
      if ($j -gt $i -and $lines[$j] -match '(?i)^\s*(constructor|procedure|function)\s') { break }
      if ($lines[$j] -match '(?i)^\s*(ClientWidth|ClientHeight|Width|Height)\s*:=\s*\d+\s*;') {
        $hits.Add(('{0}: {1}' -f ($j + 1), $lines[$j].Trim()))
      }
    }
    $C.Add(('   {0}:{1}  inherited CreateNew  (stale wymiary okna: {2})' -f $p, ($i + 1), $hits.Count))
    foreach ($h in $hits) { $C.Add('        ' + $h) }
  }
}

$out = New-Object System.Text.StringBuilder
[void]$out.AppendLine('AUDYT SZTYWNYCH OKIEN - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
[void]$out.AppendLine(('Formularze .dfm: {0}' -f $dfms.Count))
[void]$out.AppendLine('')
[void]$out.AppendLine(('A) BRAK UKLADU Z ZAWARTOSCI ({0}) - rozmiar tylko z .dfm (ClientWidth x ClientHeight, BorderStyle):' -f $A.Count))
foreach ($r in ($A | Sort-Object)) { [void]$out.AppendLine($r) }
[void]$out.AppendLine('')
[void]$out.AppendLine(('B) STALE W KODZIE ({0}) - ClientWidth/ClientHeight z liczba >= 50:' -f $B.Count))
foreach ($r in $B) { [void]$out.AppendLine($r) }
[void]$out.AppendLine('')
[void]$out.AppendLine('C) OKNA TWORZONE W KODZIE (TForm.Create):')
foreach ($r in $C) { [void]$out.AppendLine($r) }

$dst = Join-Path $root 'tools\tmp\audyt_sztywne_okna.txt'
[IO.File]::WriteAllText($dst, $out.ToString(), (New-Object System.Text.UTF8Encoding($true)))
Write-Output ('Zapisano: ' + $dst + ('  (A: {0}, B: {1}, C: {2} wpisow)' -f $A.Count, $B.Count, $C.Count))
