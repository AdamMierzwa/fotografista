object MakietaDlg: TMakietaDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Tilt-shift (miniature)'
  ClientHeight = 560
  ClientWidth = 430
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
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxPreviewPaint
  end
  object lblStrength: TLabel
    Left = 15
    Top = 331
    Width = 130
    Height = 15
    Caption = 'Strength (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbStrength: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Max = 100
    Min = 1
    Position = 50
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
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblBandY: TLabel
    Left = 15
    Top = 379
    Width = 130
    Height = 15
    Caption = 'Band position (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbBandY: TTrackBar
    Left = 15
    Top = 396
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 1
    OnChange = tbBandYChange
  end
  object lblValBandY: TLabel
    Left = 361
    Top = 400
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblBandSize: TLabel
    Left = 15
    Top = 427
    Width = 130
    Height = 15
    Caption = 'Band height (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbBandSize: TTrackBar
    Left = 15
    Top = 444
    Width = 340
    Height = 25
    Max = 100
    Min = 1
    Position = 30
    TabOrder = 2
    OnChange = tbBandSizeChange
  end
  object lblValBandSize: TLabel
    Left = 361
    Top = 448
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '30'
    StyleElements = [seClient, seBorder]
  end
  object lblFalloff: TLabel
    Left = 15
    Top = 475
    Width = 130
    Height = 15
    Caption = 'Fade (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbFalloff: TTrackBar
    Left = 15
    Top = 492
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 3
    OnChange = tbFalloffChange
  end
  object lblValFalloff: TLabel
    Left = 361
    Top = 496
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
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
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 331
    Top = 530
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
