object StencilDlg: TStencilDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Mimeograph'
  ClientHeight = 590
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
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxZoomPaint
  end
  object lblSmooth: TLabel
    Left = 15
    Top = 331
    Width = 65
    Height = 15
    Caption = 'Graininess:'
    StyleElements = [seClient, seBorder]
  end
  object tbSmooth: TTrackBar
    Left = 95
    Top = 325
    Width = 320
    Height = 30
    Max = 10
    Min = 1
    Position = 3
    TabOrder = 0
    OnChange = tbSmoothChange
  end
  object lblSmoothVal: TLabel
    Left = 95
    Top = 358
    Width = 320
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '3'
    StyleElements = [seClient, seBorder]
  end
  object lblEdge: TLabel
    Left = 15
    Top = 386
    Width = 63
    Height = 15
    Caption = 'Edge sensitivity:'
    StyleElements = [seClient, seBorder]
  end
  object tbEdge: TTrackBar
    Left = 95
    Top = 380
    Width = 320
    Height = 30
    Max = 10
    Min = 1
    Position = 3
    TabOrder = 1
    OnChange = tbEdgeChange
  end
  object lblEdgeVal: TLabel
    Left = 95
    Top = 413
    Width = 320
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '3'
    StyleElements = [seClient, seBorder]
  end
  object lblThresh: TLabel
    Left = 15
    Top = 441
    Width = 57
    Height = 15
    Caption = 'Toner:'
    StyleElements = [seClient, seBorder]
  end
  object tbThresh: TTrackBar
    Left = 95
    Top = 435
    Width = 320
    Height = 30
    Max = 255
    Position = 128
    TabOrder = 2
    OnChange = tbThreshChange
  end
  object lblThreshVal: TLabel
    Left = 95
    Top = 468
    Width = 320
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '128'
    StyleElements = [seClient, seBorder]
  end
  object lblWear: TLabel
    Left = 15
    Top = 496
    Width = 65
    Height = 15
    Caption = 'Ink wear:'
    StyleElements = [seClient, seBorder]
  end
  object tbWear: TTrackBar
    Left = 95
    Top = 490
    Width = 320
    Height = 30
    Max = 100
    Position = 0
    TabOrder = 3
    OnChange = tbWearChange
  end
  object lblWearVal: TLabel
    Left = 95
    Top = 523
    Width = 320
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object lblInk: TLabel
    Left = 15
    Top = 331
    Width = 61
    Height = 15
    Caption = 'Ink color'
    StyleElements = [seClient, seBorder]
  end
  object pboxInk: TPaintBox
    Left = 430
    Top = 351
    Width = 180
    Height = 140
    ShowHint = True
    OnMouseDown = pboxInkMouseDown
    OnMouseMove = pboxInkMouseMove
    OnPaint = pboxInkPaint
  end
  object btnOK: TButton
    Left = 240
    Top = 553
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 331
    Top = 553
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
