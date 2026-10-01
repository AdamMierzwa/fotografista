object WzmocnienieDlg: TWzmocnienieDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Photo enhancement'
  ClientHeight = 510
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
    Width = 133
    Height = 15
    Caption = 'Effect strength (0-100):'
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
  object lblSC: TLabel
    Left = 15
    Top = 379
    Width = 159
    Height = 15
    Caption = 'Smart Curves (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbSC: TTrackBar
    Left = 15
    Top = 396
    Width = 340
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 1
    OnChange = tbSCChange
  end
  object lblValSC: TLabel
    Left = 361
    Top = 400
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 460
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 326
    Top = 460
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
