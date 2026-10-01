object HistogramDlg: THistogramDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Histogram'
  ClientHeight = 395
  ClientWidth = 540
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pboxHistogram: TPaintBox
    Left = 14
    Top = 14
    Width = 512
    Height = 256
    OnPaint = pboxHistogramPaint
  end
  object btnAll: TButton
    Left = 14
    Top = 285
    Width = 75
    Height = 25
    Caption = 'All'
    TabOrder = 0
    OnClick = btnAllClick
  end
  object btnR: TButton
    Left = 95
    Top = 285
    Width = 40
    Height = 25
    Caption = 'R'
    TabOrder = 1
    OnClick = btnRClick
  end
  object btnG: TButton
    Left = 141
    Top = 285
    Width = 40
    Height = 25
    Caption = 'G'
    TabOrder = 2
    OnClick = btnGClick
  end
  object btnB: TButton
    Left = 187
    Top = 285
    Width = 40
    Height = 25
    Caption = 'B'
    TabOrder = 3
    OnClick = btnBClick
  end
  object btnLum: TButton
    Left = 233
    Top = 285
    Width = 85
    Height = 25
    Caption = 'Luminance'
    TabOrder = 4
    OnClick = btnLumClick
  end
  object btnClose: TButton
    Left = 451
    Top = 343
    Width = 75
    Height = 25
    Caption = 'Close'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object lblEqualize: TLabel
    Left = 14
    Top = 322
    Width = 121
    Height = 15
    Caption = 'Histogram equalization'
    StyleElements = [seClient, seBorder]
  end
  object btnEqLum: TButton
    Left = 14
    Top = 343
    Width = 100
    Height = 25
    Caption = 'Luminance'
    TabOrder = 6
    OnClick = btnEqLumClick
  end
  object btnEqRGB: TButton
    Left = 120
    Top = 343
    Width = 100
    Height = 25
    Caption = 'RGB'
    TabOrder = 7
    OnClick = btnEqRGBClick
  end
end
