object AgonyDlg: TAgonyDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Amiga gradient (Agony)'
  ClientHeight = 515
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
  object lblHueTop: TLabel
    Left = 15
    Top = 331
    Width = 145
    Height = 15
    Caption = 'Hue top (0-360):'
    StyleElements = [seClient, seBorder]
  end
  object tbHueTop: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Max = 360
    Position = 170
    TabOrder = 0
    OnChange = tbHueTopChange
  end
  object lblHueTopValue: TLabel
    Left = 361
    Top = 352
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '170'
    StyleElements = [seClient, seBorder]
  end
  object lblHueBot: TLabel
    Left = 15
    Top = 383
    Width = 145
    Height = 15
    Caption = 'Hue bottom (0-360):'
    StyleElements = [seClient, seBorder]
  end
  object tbHueBot: TTrackBar
    Left = 15
    Top = 400
    Width = 340
    Height = 25
    Max = 360
    TabOrder = 1
    OnChange = tbHueBotChange
  end
  object lblHueBotValue: TLabel
    Left = 361
    Top = 404
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object lblBars: TLabel
    Left = 15
    Top = 435
    Width = 166
    Height = 15
    Caption = 'Number of bands (32-256):'
    StyleElements = [seClient, seBorder]
  end
  object tbBars: TTrackBar
    Left = 15
    Top = 452
    Width = 340
    Height = 25
    Max = 256
    Min = 32
    Position = 64
    TabOrder = 2
    OnChange = tbBarsChange
  end
  object lblBarsValue: TLabel
    Left = 361
    Top = 456
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '64'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 490
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 490
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
