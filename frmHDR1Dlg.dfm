object HDR1Dlg: THDR1Dlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Vivid'
  ClientHeight = 560
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pboxPreview: TPaintBox
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxPreviewPaint
  end
  object lblStrength: TLabel
    Left = 15
    Top = 331
    Width = 157
    Height = 15
    Caption = 'Strength (0 = none, 100 = max):'
    StyleElements = [seClient, seBorder]
  end
  object tbStrength: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Max = 100
    Position = 60
    TabOrder = 0
    OnChange = tbStrengthChange
  end
  object lblValStrength: TLabel
    Left = 361
    Top = 352
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '60'
    StyleElements = [seClient, seBorder]
  end
  object lblSat: TLabel
    Left = 15
    Top = 379
    Width = 107
    Height = 15
    Caption = 'Saturation (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbSat: TTrackBar
    Left = 15
    Top = 396
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 1
    OnChange = tbSatChange
  end
  object lblValSat: TLabel
    Left = 361
    Top = 400
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblContrast: TLabel
    Left = 15
    Top = 427
    Width = 124
    Height = 15
    Caption = 'Contrast (0 = none, 100):'
    StyleElements = [seClient, seBorder]
  end
  object tbContrast: TTrackBar
    Left = 15
    Top = 444
    Width = 340
    Height = 25
    Max = 100
    Position = 40
    TabOrder = 2
    OnChange = tbContrastChange
  end
  object lblValContrast: TLabel
    Left = 361
    Top = 448
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '40'
    StyleElements = [seClient, seBorder]
  end
  object lblCurve: TLabel
    Left = 15
    Top = 475
    Width = 149
    Height = 15
    Caption = 'Shadow curve (1 = gentle, 5):'
    StyleElements = [seClient, seBorder]
  end
  object tbCurve: TTrackBar
    Left = 15
    Top = 492
    Width = 340
    Height = 25
    Max = 5
    Min = 1
    Position = 2
    TabOrder = 3
    OnChange = tbCurveChange
  end
  object lblValCurve: TLabel
    Left = 361
    Top = 496
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '2'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 530
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 326
    Top = 530
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
