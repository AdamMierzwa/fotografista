object AmigaGradientDlg: TAmigaGradientDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Amiga gradient'
  ClientHeight = 410
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
  object lblPct: TLabel
    Left = 15
    Top = 331
    Width = 145
    Height = 15
    Caption = 'Intensity (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbPct: TTrackBar
    Left = 15
    Top = 350
    Width = 340
    Height = 25
    Min = 1
    Max = 100
    Position = 60
    TabOrder = 0
    OnChange = tbPctChange
  end
  object lblPctValue: TLabel
    Left = 361
    Top = 354
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '60'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 385
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 385
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
