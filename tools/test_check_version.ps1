# test_check_version.ps1 - regresja dla tools\check_version.ps1 (bramka wersji).
# Buduje wlasne drzewo w tools\tmp\version_test\ i wstrzykuje uszkodzenia,
# wiec NIE dotyka prawdziwego repo. 3 przypadki:
#   A) FileVersion != ProductVersion w TEJ SAMEJ linijce dproj - dziura, ktora
#      przeszla do Storea razem z calym rozjazdem 1.0.6.0 vs 1.1.0.0
#   B) ProductVersion calkiem nieobecny - referencja niekompletna
#   C) wszystko zgodne -> 0
# Uzycie: powershell -NoProfile -ExecutionPolicy Bypass -File tools\test_check_version.ps1

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'check_version.ps1'
$t = Join-Path $PSScriptRoot 'tmp\version_test'

function New-Tree([string]$verInfoLine, [string]$about, [string]$ver) {
    if (Test-Path $t) { Remove-Item $t -Recurse -Force }
    $null = New-Item -ItemType Directory -Path (Join-Path $t 'tools') -Force
    $utf8bom = New-Object System.Text.UTF8Encoding($true)
    $dproj = @(
        '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">'
        '  <PropertyGroup Condition="''$(Config)==''Release''">'
        '    <Cfg_1 Condition="''$(Platform)==''Win64''">Cfg_1_Win64</Cfg_1>'
        '  </PropertyGroup>'
        '  <PropertyGroup Condition="''$(Cfg_1)==''Cfg_1_Win64''">'
        "    <VerInfo_Keys>$verInfoLine</VerInfo_Keys>"
        '  </PropertyGroup>'
        '</Project>'
    ) -join "`n"
    [System.IO.File]::WriteAllText((Join-Path $t 'Fotografista.dproj'), $dproj, $utf8bom)
    [System.IO.File]::WriteAllText((Join-Path $t 'AboutBoxUnit.pas'), "  RealAppVersion = '$about'`n", $utf8bom)
    [System.IO.File]::WriteAllText((Join-Path $t 'tools\build_msix.cmd'), "set VER=$ver`n", $utf8bom)
}

$cases = @(
    @{ Name = 'A FileVersion != ProductVersion'; Info = 'FileVersion=1.1.1.0;ProductVersion=1.0.6.0'; About = '1.1.1'; Ver = '1.1.1.0'; Want = 1; Grep = 'roznia' },
    @{ Name = 'B brak ProductVersion';            Info = 'FileVersion=1.1.1.0';                      About = '1.1.1'; Ver = '1.1.1.0'; Want = 1; Grep = 'brak ProductVersion' },
    @{ Name = 'C wszystko zgodne';                Info = 'FileVersion=1.1.1.0;ProductVersion=1.1.1.0'; About = '1.1.1'; Ver = '1.1.1.0'; Want = 0; Grep = 'OK - wszystkie' }
)

$fail = 0
foreach ($c in $cases) {
    New-Tree $c.Info $c.About $c.Ver
    $txt = (& powershell -NoProfile -ExecutionPolicy Bypass -File $script -Root $t 2>&1 | Out-String)
    $code = $LASTEXITCODE
    $ok = ($code -eq $c.Want) -and ($txt -match [regex]::Escape($c.Grep))
    if (-not $ok) { $fail++ }
    "  {0} [{1}] exit={2} oczekiwano={3} ({4})" -f $(if ($ok) { 'OK  ' } else { 'BLAD' }), $c.Name, $code, $c.Want, $c.Grep
    if (-not $ok) { $txt }
}

Remove-Item $t -Recurse -Force
if ($fail -gt 0) { "TEST: $fail przypadkow nie przeszlo"; exit 1 }
'TEST: 3/3 OK'
exit 0
