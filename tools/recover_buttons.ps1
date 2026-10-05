# recover_buttons.ps1 v3 — hardcoded button reconstruction

$ProjectDir = Split-Path -Parent $PSScriptRoot

$jobs = @(
    # Format: file, btn1_name, btn1_left, btn1_top, btn1_props..., "---", btn2_name, btn2_left, btn2_top, btn2_props...
    # Props: Caption|Default|Cancel|ModalResult=N|TabOrder=N  separated by commas

    @("frmSelSizeDlg.dfm",    "btnOK",122,125,"OK,Default,ModalResult=1,TabOrder=2",    "btnCancel",208,125,"Anuluj,Cancel,ModalResult=2,TabOrder=3"),
    @("frmGammaDlg.dfm",      "btnOK",240,400,"OK,Default,ModalResult=1,TabOrder=2",    "btnCancel",326,400,"Anuluj,Cancel,ModalResult=2,TabOrder=3"),
    @("frmHSBDlg.dfm",        "btnOK",240,510,"OK,Default,ModalResult=1,TabOrder=4",    "btnCancel",326,510,"Anuluj,Cancel,ModalResult=2,TabOrder=5"),
    @("frmWBDlg.dfm",         "btnOK",240,510,"OK,Default,ModalResult=1,TabOrder=4",    "btnCancel",326,510,"Anuluj,Cancel,ModalResult=2,TabOrder=5"),
    @("frmSharpenDlg.dfm",    "btnOK",240,400,"OK,Default,ModalResult=1,TabOrder=2",    "btnCancel",326,400,"Anuluj,Cancel,ModalResult=2,TabOrder=3"),
    @("frmLevelsDlg.dfm",     "btnOK",240,500,"OK,Default,ModalResult=1,TabOrder=4",    "btnCancel",326,500,"Anuluj,Cancel,ModalResult=2,TabOrder=5"),
    @("frmHDR1Dlg.dfm",       "btnOK",240,530,"OK,Default,ModalResult=1,TabOrder=5",    "btnCancel",326,530,"Anuluj,Cancel,ModalResult=2,TabOrder=6"),
    @("frmWzmocnienieDlg.dfm","btnOK",240,460,"OK,Default,ModalResult=1,TabOrder=3",    "btnCancel",326,460,"Anuluj,Cancel,ModalResult=2,TabOrder=4"),
    @("frmStraightenDlg.dfm", "btnOK",224,340,"OK,Default,ModalResult=1,TabOrder=1",    "btnCancel",310,340,"Anuluj,Cancel,ModalResult=2,TabOrder=2"),
    @("frmInterfaceDlg.dfm",  "btnOK",162,225,"OK,Default,ModalResult=1,TabOrder=4",    "btnCancel",248,225,"Anuluj,Cancel,ModalResult=2,TabOrder=5"),
    @("frmQualityDlg.dfm",    "btnOK",202,400,"OK,Default,ModalResult=1,TabOrder=3",    "btnCancel",288,400,"Anuluj,Cancel,ModalResult=2,TabOrder=4")
)

function Get-ButtonLines($btnName, $left, $top, $propsStr) {
    $lines = @("  object $btnName`: TButton")
    $lines += "    Left = $left"
    $lines += "    Top = $top"
    $lines += "    Width = 85"
    $lines += "    Height = 25"
    $props = $propsStr -split ','
    foreach ($p in $props) {
        if ($p -eq 'OK') { $lines += "    Caption = 'OK'" }
        elseif ($p -eq 'Anuluj') { $lines += "    Caption = 'Anuluj'" }
        elseif ($p -eq 'Zamknij') { $lines += "    Caption = 'Zamknij'" }
        elseif ($p -eq 'Default') { $lines += "    Default = True" }
        elseif ($p -eq 'Cancel') { $lines += "    Cancel = True" }
        elseif ($p -match 'ModalResult=(\d+)') { $lines += "    ModalResult = $($Matches[1])" }
        elseif ($p -match 'TabOrder=(\d+)') { $lines += "    TabOrder = $($Matches[1])" }
        elseif ($p -match 'OnClick=(.+)') { $lines += "    OnClick = $($Matches[1])" }
    }
    $lines += "  end"
    return $lines
}

foreach ($job in $jobs) {
    $file = $job[0]
    $dfmPath = Join-Path $ProjectDir $file
    if (-not (Test-Path $dfmPath)) { Write-Host "--- $file not found"; continue }

    $raw = [System.IO.File]::ReadAllBytes($dfmPath)
    $text = [System.Text.Encoding]::UTF8.GetString($raw)
    $lines = $text -split '\r?\n'

    # Strip all existing root-level TButton objects (our garbage)
    $stripBtn = $false
    $clean = @()
    foreach ($line in $lines) {
        $trim = $line.TrimStart()
        $indent = $line.Length - $trim.Length
        if ($trim -match '^object \w*: TButton$' -and $indent -eq 2) {
            $stripBtn = $true
            continue
        }
        if ($stripBtn) {
            if ($trim -eq 'end' -and $indent -eq 2) { $stripBtn = $false; continue }
            continue
        }
        $clean += $line
    }

    # Remove form's trailing end (last line with indent 0)
    $formEndLine = $clean[-1]
    $clean = $clean[0..($clean.Count - 2)]

    # Build buttons
    $btn1Name = $job[1]; $btn1Left = $job[2]; $btn1Top = $job[3]; $btn1Props = $job[4]
    $btn2Name = $job[5]; $btn2Left = $job[6]; $btn2Top = $job[7]; $btn2Props = $job[8]

    $b1 = Get-ButtonLines $btn1Name $btn1Left $btn1Top $btn1Props
    $b2 = Get-ButtonLines $btn2Name $btn2Left $btn2Top $btn2Props

    $newLines = $clean + $b1 + $b2 + @($formEndLine)

    $bom = [byte[]]@(0xEF,0xBB,0xBF)
    $stream = [System.IO.File]::Open($dfmPath, [System.IO.FileMode]::Create)
    $stream.Write($bom, 0, 3)
    $wr = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))
    for ($i = 0; $i -lt $newLines.Count; $i++) {
        if ($i -lt $newLines.Count - 1) { $wr.WriteLine($newLines[$i]) }
        else { $wr.Write($newLines[$i]) }
    }
    $wr.Close(); $stream.Close()

    Write-Host ("RESTORED " + $file)
}
