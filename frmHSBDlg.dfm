object HSBDlg: THSBDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'HSB balance'
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
  object lblHue: TLabel
    Left = 15
    Top = 331
    Width = 150
    Height = 15
    Caption = 'Hue (0-200, default 100):'
    StyleElements = [seClient, seBorder]
  end
  object tbHue: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Min = 0
    Max = 200
    Position = 100
    TabOrder = 0
    OnChange = tbHueChange
  end
  object lblValHue: TLabel
    Left = 361
    Top = 352
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblSat: TLabel
    Left = 15
    Top = 379
    Width = 160
    Height = 15
    Caption = 'Saturation (0-200, default 100):'
    StyleElements = [seClient, seBorder]
  end
  object tbSat: TTrackBar
    Left = 15
    Top = 396
    Width = 340
    Height = 25
    Min = 0
    Max = 200
    Position = 100
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
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblBri: TLabel
    Left = 15
    Top = 427
    Width = 145
    Height = 15
    Caption = 'Brightness (0-200, default 100):'
    StyleElements = [seClient, seBorder]
  end
  object tbBri: TTrackBar
    Left = 15
    Top = 444
    Width = 340
    Height = 25
    Min = 0
    Max = 200
    Position = 100
    TabOrder = 2
    OnChange = tbBriChange
  end
  object lblValBri: TLabel
    Left = 361
    Top = 448
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 510
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 326
    Top = 510
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
