object Linocut2Dlg: TLinocut2Dlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Linocut'
  ClientHeight = 500
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
  object lblThreshold: TLabel
    Left = 15
    Top = 331
    Width = 260
    Height = 15
    Caption = 'Threshold (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object tbThreshold: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Min = 1
    Max = 100
    Position = 50
    TabOrder = 0
    OnChange = tbChange
  end
  object lblThresholdVal: TLabel
    Left = 15
    Top = 379
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblSimplify: TLabel
    Left = 15
    Top = 400
    Width = 260
    Height = 15
    Caption = 'Simplification:'
    StyleElements = [seClient, seBorder]
  end
  object tbSimplify: TTrackBar
    Left = 15
    Top = 419
    Width = 400
    Height = 25
    Min = 1
    Max = 10
    Position = 6
    TabOrder = 1
    OnChange = tbChange
  end
  object lblSimplifyVal: TLabel
    Left = 15
    Top = 448
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '6'
    StyleElements = [seClient, seBorder]
  end
  object lblMinArea: TLabel
    Left = 15
    Top = 470
    Width = 260
    Height = 15
    Caption = 'Min. area (px):'
    StyleElements = [seClient, seBorder]
  end
  object tbMinArea: TTrackBar
    Left = 15
    Top = 489
    Width = 400
    Height = 25
    Max = 50
    Position = 3
    TabOrder = 2
    OnChange = tbChange
  end
  object lblMinVal: TLabel
    Left = 15
    Top = 518
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '3'
    StyleElements = [seClient, seBorder]
  end
  object lblCleanCount: TLabel
    Left = 15
    Top = 540
    Width = 94
    Height = 15
    Caption = ''
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 470
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 470
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
