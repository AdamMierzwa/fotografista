object CrosshatchDlg: TCrosshatchDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Crosshatch'
  ClientHeight = 520
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
  object lblCell: TLabel
    Left = 15
    Top = 331
    Width = 137
    Height = 15
    Caption = 'Cell size (4-16 px):'
    StyleElements = [seClient, seBorder]
  end
  object tbCell: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Min = 4
    Max = 16
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
    Width = 151
    Height = 15
    Caption = 'Maximum line thickness (1-8):'
    StyleElements = [seClient, seBorder]
  end
  object tbThick: TTrackBar
    Left = 15
    Top = 422
    Width = 400
    Height = 25
    Min = 1
    Max = 8
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
