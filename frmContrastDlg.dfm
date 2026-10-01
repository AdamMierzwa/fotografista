object ContrastDlg: TContrastDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Contrast'
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
  object lblMode: TLabel
    Left = 15
    Top = 331
    Width = 33
    Height = 15
    Caption = 'Mode:'
    StyleElements = [seClient, seBorder]
  end
  object rbIncrease: TRadioButton
    Left = 15
    Top = 352
    Width = 120
    Height = 20
    Caption = 'Increase'
    Checked = True
    TabOrder = 1
    TabStop = True
    OnClick = rbIncreaseClick
  end
  object rbDecrease: TRadioButton
    Left = 15
    Top = 378
    Width = 120
    Height = 20
    Caption = 'Decrease'
    TabOrder = 2
    OnClick = rbDecreaseClick
  end
  object lblIntensity: TLabel
    Left = 15
    Top = 411
    Width = 140
    Height = 15
    Caption = 'Intensity (1-10):'
    StyleElements = [seClient, seBorder]
  end
  object tbAmount: TTrackBar
    Left = 15
    Top = 427
    Width = 300
    Height = 25
    Max = 10
    Min = 1
    Position = 3
    TabOrder = 3
    OnChange = tbAmountChange
  end
  object lblValue: TLabel
    Left = 321
    Top = 431
    Width = 30
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '3'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 470
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 326
    Top = 470
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
