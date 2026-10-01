object SharpenDlg: TSharpenDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Sharpen'
  ClientHeight = 460
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
  object lblIntensity: TLabel
    Left = 15
    Top = 331
    Width = 147
    Height = 15
    Caption = 'Intensity (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbAmount: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Min = 1
    Max = 100
    Position = 20
    TabOrder = 0
    OnChange = tbAmountChange
  end
  object lblValue: TLabel
    Left = 361
    Top = 352
    Width = 40
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '20'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 400
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 326
    Top = 400
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
