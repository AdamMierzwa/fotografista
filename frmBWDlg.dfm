object BWDlg: TBWDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Black & white'
  ClientHeight = 545
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
    OnMouseMove = pboxPreviewMouseMove
    OnPaint = pboxPreviewPaint
  end
  object pboxZoom: TPaintBox
    Left = 430
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxZoomPaint
  end
  object lblBrightness: TLabel
    Left = 15
    Top = 331
    Width = 150
    Height = 15
    Caption = 'Brightness before conversion (0-200):'
    StyleElements = [seClient, seBorder]
  end
  object tbBrightness: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Max = 200
    Min = 0
    Position = 100
    TabOrder = 0
    OnChange = tbBrightnessChange
  end
  object lblBValue: TLabel
    Left = 15
    Top = 378
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblContrast: TLabel
    Left = 15
    Top = 381
    Width = 145
    Height = 15
    Caption = 'Contrast before conversion (0-10):'
    StyleElements = [seClient, seBorder]
  end
  object tbContrast: TTrackBar
    Left = 15
    Top = 400
    Width = 400
    Height = 25
    Max = 10
    Min = 0
    TabOrder = 1
    OnChange = tbContrastChange
  end
  object lblCValue: TLabel
    Left = 15
    Top = 428
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object rgDither: TRadioGroup
    Left = 15
    Top = 430
    Width = 400
    Height = 75
    Caption = 'Dithering'
    Columns = 1
    TabOrder = 2
    OnClick = rgDitherClick
  end
  object btnOK: TButton
    Left = 240
    Top = 515
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 515
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
