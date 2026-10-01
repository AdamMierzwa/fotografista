object LevelsDlg: TLevelsDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Levels'
  ClientHeight = 550
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
  object lblBlack: TLabel
    Left = 15
    Top = 328
    Width = 133
    Height = 15
    Caption = 'Black point (0-255):'
    StyleElements = [seClient, seBorder]
  end
  object tbBlack: TTrackBar
    Left = 15
    Top = 345
    Width = 370
    Height = 25
    Max = 255
    Position = 0
    TabOrder = 0
    OnChange = tbBlackChange
  end
  object lblBlackVal: TLabel
    Left = 15
    Top = 372
    Width = 370
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object lblGamma: TLabel
    Left = 15
    Top = 380
    Width = 176
    Height = 15
    Caption = 'Gamma (10-500, 100=1.0):'
    StyleElements = [seClient, seBorder]
  end
  object tbGamma: TTrackBar
    Left = 15
    Top = 397
    Width = 370
    Height = 25
    Max = 500
    Min = 10
    Position = 100
    TabOrder = 1
    OnChange = tbGammaChange
  end
  object lblGammaVal: TLabel
    Left = 15
    Top = 424
    Width = 370
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblWhite: TLabel
    Left = 15
    Top = 432
    Width = 126
    Height = 15
    Caption = 'White point (0-255):'
    StyleElements = [seClient, seBorder]
  end
  object tbWhite: TTrackBar
    Left = 15
    Top = 449
    Width = 370
    Height = 25
    Max = 255
    Position = 255
    TabOrder = 2
    OnChange = tbWhiteChange
  end
  object lblWhiteVal: TLabel
    Left = 15
    Top = 476
    Width = 370
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '255'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 500
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 326
    Top = 500
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
