# recover_dfm.ps1 v2 — rebuild DFMs corrupted by fix_buttons.ps1

$ProjectDir = Split-Path -Parent $PSScriptRoot

$files = @(
    "frmSelSizeDlg.dfm","frmGammaDlg.dfm","frmHSBDlg.dfm","frmWBDlg.dfm",
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

    # Find where corruption starts — first "object pnlBottom: TPanel"
    $cutIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $trim = $lines[$i].TrimStart()
        if ($trim -eq 'object pnlBottom: TPanel') { $cutIdx = $i; break }
    }

    if ($cutIdx -lt 0) { Write-Host "--- $f no pnlBottom found (already clean?)"; continue }

    # Keep everything before corruption
    $prefix = $lines[0..($cutIdx - 1)]

    # From the corrupted tail, extract TButton blocks at 2-space indent
    $buttons = @()
    $i = $cutIdx
    while ($i -lt $lines.Count) {
        $trim = $lines[$i].TrimStart()
        $indent = $lines[$i].Length - $trim.Length
        if ($trim -match '^object (btn\w+): TButton$' -and $indent -eq 2) {
            $btnName = $Matches[1]
            $props = @()
            $i++
            while ($i -lt $lines.Count) {
                $t2 = $lines[$i].TrimStart()
                $i2 = $lines[$i].Length - $t2.Length
                if ($t2 -eq 'end' -and $i2 -eq 2) {
                    # End of button block
                    break
                }
                $props += $t2  # store trimmed, we'll re-indent
                $i++
            }
            $buttons += @{ Name = $btnName; Props = $props }
        }
        $i++
    }

    if ($buttons.Count -eq 0) {
        Write-Host "--- $f no buttons found in tail"
        # Just keep prefix and add form end
        $prefix += "end"
    } else {
        # Reconstruct buttons at root level
        foreach ($btn in $buttons) {
            $prefix += "  object $($btn.Name): TButton"
            foreach ($p in $btn.Props) { $prefix += "    $p" }
            $prefix += "  end"
        }
        $prefix += "end"
    }

    # Write with BOM
    $bom = [byte[]]@(0xEF,0xBB,0xBF)
    $stream = [System.IO.File]::Open($dfmPath, [System.IO.FileMode]::Create)
    $stream.Write($bom, 0, 3)
    $wr = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))
    for ($i = 0; $i -lt $prefix.Count; $i++) {
        if ($i -lt $prefix.Count - 1) { $wr.WriteLine($prefix[$i]) }
        else { $wr.Write($prefix[$i]) }
    }
    $wr.Close(); $stream.Close()

    Write-Host "RECOVERED $f — $($buttons.Count) buttons restored"
}