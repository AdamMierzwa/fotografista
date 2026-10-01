object EmbossDlg: TEmbossDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Emboss'
  ClientHeight = 430
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
  object lblLabel: TLabel
    Left = 15
    Top = 331
    Width = 260
    Height = 15
    Caption = 'Intensity (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblValue: TLabel
    Left = 15
    Top = 378
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '30'
    StyleElements = [seClient, seBorder]
  end
  object tbAmount: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Min = 1
    Max = 100
    Position = 30
    TabOrder = 0
    OnChange = tbAmountChange
  end
  object btnOK: TButton
    Left = 240
    Top = 400
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 400
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
