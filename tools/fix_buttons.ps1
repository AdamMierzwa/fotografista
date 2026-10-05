# fix_buttons.ps1 - wrap root-level action buttons into pnlBottom

$ProjectDir = Split-Path -Parent $PSScriptRoot

$ActionNames = @("btnOK","btnCancel","btnClose","btnAnuluj","btnZamknij","btnApply")

function Indent($s) { $s.Length - $s.TrimStart().Length }

function FindBlockEnd($lines, $start) {
    $indent = Indent $lines[$start]
    $skip = 0
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].TrimStart()
        if ($t -match '^object ') { $skip++ }
        elseif ($t -eq 'end') {
            if ($skip -gt 0) { $skip-- }
            elseif ((Indent $lines[$i]) -eq $indent) { return $i }
        }
    }
    return -1
}

$files = @(
    "frmSelSizeDlg.dfm",
    "frmGammaDlg.dfm","frmHSBDlg.dfm","frmWBDlg.dfm",
    "frmSharpenDlg.dfm","frmLevelsDlg.dfm",
    "frmHDR1Dlg.dfm","frmWzmocnienieDlg.dfm",
    "frmStraightenDlg.dfm","frmInterfaceDlg.dfm","frmQualityDlg.dfm"
)

foreach ($f in $files) {
    $dfmPath = Join-Path $ProjectDir $f
    if (-not (Test-Path $dfmPath)) { Write-Host "--- $f not found"; continue }

    $raw = [System.IO.File]::ReadAllBytes($dfmPath)
    $text = [System.Text.Encoding]::UTF8.GetString($raw)
    $lines = $text -split '\r?\n'

    $formEnd = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimStart() -eq 'end' -and (Indent $lines[$i]) -eq 0) { $formEnd = $i; break }
    }
    if ($formEnd -lt 0) { Write-Host "--- $f no form end"; continue }

    $btns = @()
    for ($i = 0; $i -lt $formEnd; ) {
        $line = $lines[$i]
        if ((Indent $line) -eq 2 -and $line -match '^  object (\w+): TButton$') {
            $name = $Matches[1]
            $endIdx = FindBlockEnd $lines $i
            if ($endIdx -gt 0 -and $endIdx -lt $formEnd) {
                $btns += @{ Name = $name; Start = $i; End = $endIdx }
                $i = $endIdx + 1
            } else { $i++ }
        } else { $i++ }
    }

    $actionIdx = @()
    for ($b = $btns.Count - 1; $b -ge 0; $b--) {
        if ($ActionNames -contains $btns[$b].Name) { $actionIdx = @($b) + $actionIdx }
        else { break }
    }
    if ($actionIdx.Count -eq 0) { Write-Host "--- $f no action buttons"; continue }

    $aStart = $btns[$actionIdx[0]].Start
    $aEnd = $btns[$actionIdx[-1]].End

    $cw = 300
    for ($i = 0; $i -lt $formEnd; $i++) {
        if ($lines[$i] -match '^\s+ClientWidth\s*=\s*(\d+)') { $cw = [int]$Matches[1] }
    }

    $topY = 90
    $fb = $btns[$actionIdx[0]]
    for ($i = $fb.Start + 1; $i -lt $fb.End; $i++) {
        if ($lines[$i].Trim() -match '^Top\s*=\s*(\d+)') { $topY = [int]$Matches[1] }
    }

    $btnBlocks = @()
    foreach ($bi in $actionIdx) {
        $b = $btns[$bi]
        $btnBlocks += @( $lines[$b.Start] )
        $hasWidth = $false; $hasHeight = $false; $hasAlign = $false
        for ($j = $b.Start + 1; $j -lt $b.End; $j++) {
            $t = $lines[$j].Trim()
            if ($t -match '^(Width|Height|Align)\s*=') {
                if ($t -match '^Width') { $hasWidth = $true }
                elseif ($t -match '^Height') { $hasHeight = $true }
                elseif ($t -match '^Align') { $hasAlign = $true }
                continue
            }
            $btnBlocks += @( "    $t" )
        }
        if (-not $hasWidth)  { $btnBlocks += @( "    Width = 85" ) }
        if (-not $hasHeight) { $btnBlocks += @( "    Height = 25" ) }
        if (-not $hasAlign)  { $btnBlocks += @( "    Align = alRight" ) }
        $btnBlocks += @( "    end" )
    }

    $pnl = @()
    $pnl += "  object pnlBottom: TPanel"
    $pnl += "    Left = 0"
    $pnl += "    Top = $topY"
    $pnl += "    Width = $cw"
    $pnl += "    Align = alBottom"
    $pnl += "    BevelOuter = bvNone"
    $pnl += "    TabOrder = 99"
    foreach ($bl in $btnBlocks) {
        $t = $bl
        if ($t -match '^  ') { $t = "  " + $t.TrimStart() }
        $pnl += $t
    }
    $pnl += "  end"

    $newLines = $lines[0..($aStart - 1)] + $pnl + $lines[($aEnd + 1)..($lines.Count - 1)]

    $bom = [byte[]]@(0xEF,0xBB,0xBF)
    $stream = [System.IO.File]::Open($dfmPath, [System.IO.FileMode]::Create)
    $stream.Write($bom, 0, 3)
    $wr = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))
    for ($i = 0; $i -lt $newLines.Count; $i++) {
        if ($i -lt $newLines.Count - 1) { $wr.WriteLine($newLines[$i]) }
        else { $wr.Write($newLines[$i]) }
    }
    $wr.Close()
    $stream.Close()

    Write-Host "DFM $f wrapped $($actionIdx.Count) buttons"
}