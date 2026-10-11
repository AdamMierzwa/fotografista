object PoissonDlg: TPoissonDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Poisson dots (experimental)'
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
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxZoomPaint
  end
  object lblSize: TLabel
    Left = 15
    Top = 331
    Caption = 'Dot size (0.1-10.0% of short side):'
    StyleElements = [seClient, seBorder]
  end
  object tbSize: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Min = 1
    Max = 100
    Position = 4
    TabOrder = 0
    OnChange = tbParamChange
  end
  object lblSizeVal: TLabel
    Left = 15
    Top = 379
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0.4%'
    StyleElements = [seClient, seBorder]
  end
  object lblGamma: TLabel
    Left = 15
    Top = 403
    Caption = 'Tone curve (10-500, 100 = linear):'
    StyleElements = [seClient, seBorder]
  end
  object tbGamma: TTrackBar
    Left = 15
    Top = 422
    Width = 400
    Height = 25
    Min = 10
    Max = 500
    Position = 100
    TabOrder = 1
    OnChange = tbParamChange
  end
  object lblGammaVal: TLabel
    Left = 15
    Top = 451
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblStatus: TLabel
    Left = 15
    Top = 475
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 490
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 331
    Top = 490
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
