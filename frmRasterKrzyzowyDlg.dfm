object RasterKrzyzowyDlg: TRasterKrzyzowyDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Cross raster'
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
    OnChange = tbCellChange
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
  object lblThick: TLabel
    Left = 15
    Top = 403
    Caption = 'Maximum line thickness (1-64):'
    StyleElements = [seClient, seBorder]
  end
  object tbThick: TTrackBar
    Left = 15
    Top = 422
    Width = 400
    Height = 25
    Min = 1
    Max = 64
    Position = 4
    TabOrder = 1
    OnChange = tbThickChange
  end
  object lblThickVal: TLabel
    Left = 15
    Top = 451
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '4'
    StyleElements = [seClient, seBorder]
  end
  object lblAngle1: TLabel
    Left = 15
    Top = 475
    Caption = 'Line angle 1 (0-179°):'
    StyleElements = [seClient, seBorder]
  end
  object tbAngle1: TTrackBar
    Left = 15
    Top = 494
    Width = 400
    Height = 25
    Max = 179
    Position = 45
    TabOrder = 2
    OnChange = tbAngleChange
  end
  object lblAngle1Val: TLabel
    Left = 15
    Top = 523
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '45'
    StyleElements = [seClient, seBorder]
  end
  object lblAngle2: TLabel
    Left = 15
    Top = 547
    Caption = 'Line angle 2 (0-179°):'
    StyleElements = [seClient, seBorder]
  end
  object tbAngle2: TTrackBar
    Left = 15
    Top = 566
    Width = 400
    Height = 25
    Max = 179
    Position = 135
    TabOrder = 3
    OnChange = tbAngleChange
  end
  object lblAngle2Val: TLabel
    Left = 15
    Top = 595
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '135'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 630
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 331
    Top = 630
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
