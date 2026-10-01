object TshirtDlg: TTshirtDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'T-Shirt Design'
  ClientHeight = 525
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pboxPreview: TPaintBox
    Left = 452
    Top = 19
    Width = 305
    Height = 465
    OnPaint = pboxPreviewPaint
  end
  object grpStage1: TGroupBox
    Left = 15
    Top = 15
    Width = 418
    Height = 60
    Caption = '1. Posterization'
    TabOrder = 0
    object lblColors: TLabel
      Left = 10
      Top = 24
      Width = 82
      Height = 15
      Caption = 'Number of colors:'
      StyleElements = [seClient, seBorder]
    end
    object cmbColors: TComboBox
      Left = 104
      Top = 20
      Width = 60
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cmbColorsChange
    end
  end
  object grpStage2: TGroupBox
    Left = 15
    Top = 85
    Width = 418
    Height = 220
    Caption = '2. Color to ink mapping'
    TabOrder = 1
    object swInk0: TShape
      Left = 10
      Top = 22
      Width = 24
      Height = 24
      Pen.Style = psClear
    end
    object lblPal0: TLabel
      Left = 38
      Top = 25
      Width = 81
      Height = 15
      Caption = 'Assign ink 1'
      StyleElements = [seClient, seBorder]
    end
    object lblInk0: TLabel
      Left = 252
      Top = 25
      Width = 32
      Height = 15
      AutoSize = False
      Caption = 'Ink:'
      StyleElements = [seClient, seBorder]
    end
    object swInk1: TShape
      Left = 10
      Top = 55
      Width = 24
      Height = 24
      Pen.Style = psClear
    end
    object lblPal1: TLabel
      Left = 38
      Top = 58
      Width = 81
      Height = 15
      Caption = 'Assign ink 2'
      StyleElements = [seClient, seBorder]
    end
    object lblInk1: TLabel
      Left = 252
      Top = 58
      Width = 32
      Height = 15
      AutoSize = False
      Caption = 'Ink:'
      StyleElements = [seClient, seBorder]
    end
    object swInk2: TShape
      Left = 10
      Top = 88
      Width = 24
      Height = 24
      Pen.Style = psClear
    end
    object lblPal2: TLabel
      Left = 38
      Top = 91
      Width = 81
      Height = 15
      Caption = 'Assign ink 3'
      StyleElements = [seClient, seBorder]
    end
    object lblInk2: TLabel
      Left = 252
      Top = 91
      Width = 32
      Height = 15
      AutoSize = False
      Caption = 'Ink:'
      StyleElements = [seClient, seBorder]
    end
    object swInk3: TShape
      Left = 10
      Top = 121
      Width = 24
      Height = 24
      Pen.Style = psClear
    end
    object lblPal3: TLabel
      Left = 38
      Top = 124
      Width = 81
      Height = 15
      Caption = 'Assign ink 4'
      StyleElements = [seClient, seBorder]
    end
    object lblInk3: TLabel
      Left = 252
      Top = 124
      Width = 32
      Height = 15
      AutoSize = False
      Caption = 'Ink:'
      StyleElements = [seClient, seBorder]
    end
    object swInk4: TShape
      Left = 10
      Top = 154
      Width = 24
      Height = 24
      Pen.Style = psClear
    end
    object lblPal4: TLabel
      Left = 38
      Top = 157
      Width = 81
      Height = 15
      Caption = 'Assign ink 5'
      StyleElements = [seClient, seBorder]
    end
    object lblInk4: TLabel
      Left = 252
      Top = 157
      Width = 32
      Height = 15
      AutoSize = False
      Caption = 'Ink:'
      StyleElements = [seClient, seBorder]
    end
    object swInk5: TShape
      Left = 10
      Top = 187
      Width = 24
      Height = 24
      Pen.Style = psClear
    end
    object lblPal5: TLabel
      Left = 38
      Top = 190
      Width = 81
      Height = 15
      Caption = 'Assign ink 6'
      StyleElements = [seClient, seBorder]
    end
    object lblInk5: TLabel
      Left = 252
      Top = 190
      Width = 32
      Height = 15
      AutoSize = False
      Caption = 'Ink:'
      StyleElements = [seClient, seBorder]
    end
    object btnInk0: TButton
      Left = 145
      Top = 21
      Width = 100
      Height = 25
      Caption = 'Select'
      TabOrder = 0
      OnClick = btnInk0Click
    end
    object btnInk1: TButton
      Left = 145
      Top = 54
      Width = 100
      Height = 25
      Caption = 'Select'
      TabOrder = 1
      OnClick = btnInk1Click
    end
    object btnInk2: TButton
      Left = 145
      Top = 87
      Width = 100
      Height = 25
      Caption = 'Select'
      TabOrder = 2
      OnClick = btnInk2Click
    end
    object btnInk3: TButton
      Left = 145
      Top = 120
      Width = 100
      Height = 25
      Caption = 'Select'
      TabOrder = 3
      OnClick = btnInk3Click
    end
    object btnInk4: TButton
      Left = 145
      Top = 153
      Width = 100
      Height = 25
      Caption = 'Select'
      TabOrder = 4
      OnClick = btnInk4Click
    end
    object btnInk5: TButton
      Left = 145
      Top = 186
      Width = 100
      Height = 25
      Caption = 'Select'
      TabOrder = 5
      OnClick = btnInk5Click
    end
  end
  object grpStage3: TGroupBox
    Left = 15
    Top = 315
    Width = 418
    Height = 95
    Caption = '3. Detail cleanup'
    TabOrder = 2
    object lblMinArea: TLabel
      Left = 10
      Top = 24
      Width = 87
      Height = 15
      Caption = 'Min. area (px):'
      StyleElements = [seClient, seBorder]
    end
    object lblMinVal: TLabel
      Left = 104
      Top = 48
      Width = 180
      Height = 18
      AutoSize = False
      Alignment = taCenter
      Caption = '0'
      StyleElements = [seClient, seBorder]
    end
    object lblCleanCount: TLabel
      Left = 10
      Top = 70
      Width = 94
      Height = 15
      Caption = 'Islands removed: 0'
      StyleElements = [seClient, seBorder]
    end
    object tbMinArea: TTrackBar
      Left = 104
      Top = 20
      Width = 180
      Height = 25
      Max = 50
      TabOrder = 0
      OnChange = tbMinAreaChange
    end
  end
  object grpStage4: TGroupBox
    Left = 15
    Top = 420
    Width = 418
    Height = 105
    Caption = '4. Screen print'
    TabOrder = 3
    object lblCellMult: TLabel
      Left = 10
      Top = 52
      Width = 136
      Height = 15
      Caption = 'Dot size multiplier:'
      StyleElements = [seClient, seBorder]
    end
    object lblCellMultVal: TLabel
      Left = 150
      Top = 76
      Width = 200
      Height = 18
      AutoSize = False
      Alignment = taCenter
      Caption = '1×'
      StyleElements = [seClient, seBorder]
    end
    object chkRaster: TCheckBox
      Left = 10
      Top = 22
      Width = 250
      Height = 17
      Caption = 'Simulate screenprint raster'
      TabOrder = 0
      OnClick = chkRasterClick
    end
    object tbCellMult: TTrackBar
      Left = 150
      Top = 48
      Width = 200
      Height = 25
      Max = 4
      Min = 1
      Position = 1
      TabOrder = 1
      OnChange = tbCellMultChange
    end
  end
  object btnOK: TButton
    Left = 560
    Top = 490
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 651
    Top = 490
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
