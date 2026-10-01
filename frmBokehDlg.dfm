object BokehDlg: TBokehDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Fake bokeh'
  ClientHeight = 608
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
  object lblCx: TLabel
    Left = 15
    Top = 379
    Width = 130
    Height = 15
    Caption = 'Center X (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbCx: TTrackBar
    Left = 15
    Top = 396
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 1
    OnChange = tbCxChange
  end
  object lblValCx: TLabel
    Left = 361
    Top = 400
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblCy: TLabel
    Left = 15
    Top = 427
    Width = 130
    Height = 15
    Caption = 'Center Y (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbCy: TTrackBar
    Left = 15
    Top = 444
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 2
    OnChange = tbCyChange
  end
  object lblValCy: TLabel
    Left = 361
    Top = 448
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblRadius: TLabel
    Left = 15
    Top = 475
    Width = 130
    Height = 15
    Caption = 'Radius (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbRadius: TTrackBar
    Left = 15
    Top = 492
    Width = 340
    Height = 25
    Max = 100
    Min = 1
    Position = 30
    TabOrder = 3
    OnChange = tbRadiusChange
  end
  object lblValRadius: TLabel
    Left = 361
    Top = 496
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '30'
    StyleElements = [seClient, seBorder]
  end
  object lblFalloff: TLabel
    Left = 15
    Top = 523
    Width = 130
    Height = 15
    Caption = 'Fade (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbFalloff: TTrackBar
    Left = 15
    Top = 540
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 4
    OnChange = tbFalloffChange
  end
  object lblValFalloff: TLabel
    Left = 361
    Top = 544
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 578
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 331
    Top = 578
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
