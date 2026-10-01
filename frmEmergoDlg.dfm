object EmergoDlg: TEmergoDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Emergo'
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
    Width = 145
    Height = 15
    Caption = 'Intensity (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbIntensity: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Max = 100
    Position = 0
    TabOrder = 0
    OnChange = tbIntensityChange
  end
  object lblValIntensity: TLabel
    Left = 361
    Top = 352
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 400
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 326
    Top = 400
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
