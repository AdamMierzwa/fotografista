object KolorowanieDlg: TKolorowanieDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Colorize'
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
  object btnPickColor: TButton
    Left = 15
    Top = 327
    Width = 130
    Height = 25
    Caption = 'Choose color...'
    TabOrder = 0
    OnClick = btnPickColorClick
  end
  object lblIntensity: TLabel
    Left = 15
    Top = 360
    Width = 134
    Height = 15
    Caption = 'Intensity (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbIntensity: TTrackBar
    Left = 15
    Top = 383
    Width = 340
    Height = 25
    Min = 0
    Max = 100
    Position = 50
    TabOrder = 1
    OnChange = tbIntensityChange
  end
  object lblValIntensity: TLabel
    Left = 361
    Top = 386
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 420
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 420
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
