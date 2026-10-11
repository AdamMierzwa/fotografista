object RasterPunktowyDlg: TRasterPunktowyDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Dot raster'
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
  object lblCell: TLabel
    Left = 15
    Top = 331
    Caption = 'Cell size (4-64 px):'
    StyleElements = [seClient, seBorder]
  end
  object tbCell: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Min = 4
    Max = 64
    Position = 8
    TabOrder = 0
    OnChange = tbParamChange
  end
  object lblCellVal: TLabel
    Left = 15
    Top = 379
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '8'
    StyleElements = [seClient, seBorder]
  end
  object lblAngle: TLabel
    Left = 15
    Top = 403
    Caption = 'Dot screen angle (0-45°):'
    StyleElements = [seClient, seBorder]
  end
  object tbAngle: TTrackBar
    Left = 15
    Top = 422
    Width = 400
    Height = 25
    Max = 45
    Position = 45
    TabOrder = 1
    OnChange = tbParamChange
  end
  object lblAngleVal: TLabel
    Left = 15
    Top = 451
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '45'
    StyleElements = [seClient, seBorder]
  end
  object lblRad: TLabel
    Left = 15
    Top = 475
    Caption = 'Maximum dot size (10-100%):'
    StyleElements = [seClient, seBorder]
  end
  object tbRad: TTrackBar
    Left = 15
    Top = 494
    Width = 400
    Height = 25
    Min = 10
    Max = 100
    Position = 70
    TabOrder = 2
    OnChange = tbParamChange
  end
  object lblRadVal: TLabel
    Left = 15
    Top = 523
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '70'
    StyleElements = [seClient, seBorder]
  end
  object lblGamma: TLabel
    Left = 15
    Top = 547
    Caption = 'Tone curve (30-300, 100 = linear):'
    StyleElements = [seClient, seBorder]
  end
  object tbGamma: TTrackBar
    Left = 15
    Top = 566
    Width = 400
    Height = 25
    Min = 30
    Max = 300
    Position = 100
    TabOrder = 3
    OnChange = tbParamChange
  end
  object lblGammaVal: TLabel
    Left = 15
    Top = 595
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblSoft: TLabel
    Left = 15
    Top = 619
    Caption = 'Edge smoothing (0.0-2.0 px):'
    StyleElements = [seClient, seBorder]
  end
  object tbSoft: TTrackBar
    Left = 15
    Top = 638
    Width = 400
    Height = 25
    Max = 20
    Position = 10
    TabOrder = 4
    OnChange = tbParamChange
  end
  object lblSoftVal: TLabel
    Left = 15
    Top = 667
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '1.0'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 700
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 331
    Top = 700
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
