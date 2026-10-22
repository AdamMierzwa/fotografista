object HistogramDlg: THistogramDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Histogram'
  ClientHeight = 440
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
  object lblInfo: TLabel
    Left = 14
    Top = 282
    Width = 70
    Height = 15
    Caption = 'Information'
    StyleElements = [seClient, seBorder]
  end
  object lblDist: TLabel
    Left = 24
    Top = 309
    Width = 100
    Height = 15
    Caption = 'Color distribution'
    StyleElements = [seClient, seBorder]
  end
  object btnAll: TButton
    Left = 140
    Top = 304
    Width = 75
    Height = 25
    Caption = 'All'
    TabOrder = 0
    OnClick = btnAllClick
  end
  object btnR: TButton
    Left = 221
    Top = 304
    Width = 40
    Height = 25
    Caption = 'R'
    TabOrder = 1
    OnClick = btnRClick
  end
  object btnG: TButton
    Left = 267
    Top = 304
    Width = 40
    Height = 25
    Caption = 'G'
    TabOrder = 2
    OnClick = btnGClick
  end
  object btnB: TButton
    Left = 313
    Top = 304
    Width = 40
    Height = 25
    Caption = 'B'
    TabOrder = 3
    OnClick = btnBClick
  end
  object btnLum: TButton
    Left = 380
    Top = 304
    Width = 85
    Height = 25
    Caption = 'Brightness'
    TabOrder = 4
    OnClick = btnLumClick
  end
  object lblEqualize: TLabel
    Left = 14
    Top = 342
    Width = 70
    Height = 15
    Caption = 'Equalization'
    StyleElements = [seClient, seBorder]
  end
  object rbEqNone: TRadioButton
    Left = 24
    Top = 364
    Width = 120
    Height = 20
    Caption = 'No equalization'
    TabOrder = 5
    OnClick = rbEqClick
  end
  object rbEqRGB: TRadioButton
    Left = 150
    Top = 364
    Width = 160
    Height = 20
    Caption = 'Equalize RGB channels'
    TabOrder = 6
    OnClick = rbEqClick
  end
  object rbEqLum: TRadioButton
    Left = 316
    Top = 364
    Width = 150
    Height = 20
    Caption = 'Equalize brightness'
    TabOrder = 7
    OnClick = rbEqClick
  end
  object btnOK: TButton
    Left = 360
    Top = 398
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 8
  end
  object btnCancel: TButton
    Left = 446
    Top = 398
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 9
  end
end
