object QuantizeDlg: TQuantizeDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Posterize'
  ClientHeight = 460
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
  object lblColors: TLabel
    Left = 15
    Top = 331
    Width = 187
    Height = 15
    Caption = 'Number of colors (2-64):'
    StyleElements = [seClient, seBorder]
  end
  object tbColors: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Max = 64
    Min = 2
    Position = 8
    TabOrder = 0
    OnChange = tbColorsChange
  end
  object lblCValue: TLabel
    Left = 15
    Top = 378
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '8'
    StyleElements = [seClient, seBorder]
  end
  object rgDither: TRadioGroup
    Left = 15
    Top = 380
    Width = 400
    Height = 45
    Caption = 'Dithering'
    Columns = 2
    TabOrder = 1
    OnClick = rgDitherClick
  end
  object btnOK: TButton
    Left = 240
    Top = 435
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 331
    Top = 435
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
